#import "ViewController.h"
#import "HeraldRPC.h"
#import <Speech/Speech.h>

#define TIMEOUT 3.0

@interface ViewController () <SFSpeechRecognizerDelegate>

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) AVAudioInputNode *audioInputNode;

@property (nonatomic, strong) NSTimer *timeout;
@property (nonatomic, strong) NSTimer *timeoutProgress;

@property (nonatomic, weak) IBOutlet UIProgressView *timeoutProgressView;
@property (nonatomic, weak) IBOutlet UILabel *recognizedTextLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	//	self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]];
	self.speechRecognizer.delegate = self;
	self.audioEngine = [AVAudioEngine new];
	self.audioInputNode = self.audioEngine.inputNode;

	NSError *error;
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
	[audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];

	for (AVAudioSessionPortDescription *desc in audioSession.availableInputs) {
		NSLog(@"%@", desc);
		//[audioSession setPreferredInput:desc error:nil];
	}
	
	AVAudioFormat *recordingFormat = [self.audioInputNode outputFormatForBus:0];
	[self.audioInputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
		[self.recognitionRequest appendAudioPCMBuffer:buffer];
	}];

	[self.audioEngine prepare];

	self.timeoutProgress = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
		if (self.timeout == nil) {
			return;
		}
		self.timeoutProgressView.progress = (TIMEOUT - [self.timeout.fireDate timeIntervalSinceNow]) / TIMEOUT;
	}];

	[HeraldRPC sharedInstance];
//	[[HeraldRPC sharedInstance] skill:@"play_poneys" withArgs:@[@"kodi"]];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)listen {
	if (self.audioEngine.isRunning) {
		[self stop];
		return;
	}

	self.timeoutProgressView.progress = 0.0;
	self.timeoutProgressView.hidden = NO;
	[self.activityIndicator startAnimating];
	
	self.recognitionRequest = [SFSpeechAudioBufferRecognitionRequest new];
	self.recognitionRequest.shouldReportPartialResults = YES;
	self.recognitionRequest.contextualStrings = @[@"пони", @"поней"];
	self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult *result, NSError *error) {
		if (self.recognitionRequest == nil) {
			return;
		}
		if (result) {
			NSLog(@"RESULT: %@", result.bestTranscription.formattedString);
			for (SFTranscription *transcription in result.transcriptions) {
				NSLog(@"  - %@", transcription.formattedString);
			}
			[self.timeout invalidate];
			self.timeout = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT repeats:NO block:^(NSTimer *timer) {
				[self stop];
			}];
			self.recognizedTextLabel.text = result.bestTranscription.formattedString;
		}
		if (error) {
			[self stop];
		}
	}];
	
	NSError *error;
	[self.audioEngine startAndReturnError:&error];
	NSLog(@"Say Something, I'm listening");
	self.timeout = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT repeats:NO block:^(NSTimer *timer) {
		[self stop];
	}];
}

- (void)stop {
	self.timeoutProgressView.progress = 1.0;
	self.timeoutProgressView.hidden = YES;
	[self.activityIndicator stopAnimating];
	[self.audioEngine stop];
	[self.recognitionRequest endAudio];
	[self.recognitionTask cancel];
	[self.timeout invalidate];
	self.recognitionRequest = nil;
	self.recognitionTask = nil;
	self.timeout = nil;
	NSLog(@"Stopped");
}

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
	NSLog(@"Availability: %d", available);
}

@end
