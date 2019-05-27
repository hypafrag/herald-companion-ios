//
//  HeraldRPC.m
//  herald
//
//  Created by hypafrag on 05/07/2018.
//  Copyright © 2018 coons club. All rights reserved.
//

#import "HeraldRPC.h"
#import <SocketRocket/SocketRocket.h>

@interface HeraldRPC () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *websocket;
@property (nonatomic, assign) int requestCounter;

@end

@implementation HeraldRPC

+ (instancetype)sharedInstance {
	static HeraldRPC *instance = nil;
	if (instance == nil) {
		instance = [HeraldRPC new];
	}
	return instance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		self.requestCounter = 0;
		[self connect];
	}
	return self;
}

- (NSDictionary *)requestDictForMethod:(NSString *)method withParams:(NSDictionary *)params {
	return @{
		@"jsonrpc": @"2.0",
		@"id": @(++self.requestCounter),
		@"method": method,
		@"params": params
	};
}

- (NSString *)requestBodyForMethod:(NSString *)method withParams:(NSDictionary *)params {
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self requestDictForMethod:method withParams:params] options:0 error:nil];
	NSString *body = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	NSLog(@"HeraldRPC request: %@", body);
	return body;
}

- (void)connect {
	if (self.websocket != nil) {
		return;
	}
	self.websocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://server.local:5246"]];
	self.websocket.delegate = self;
	[self.websocket open];
}

- (void)say:(NSString *)phrase {
	if (self.websocket.readyState == SR_OPEN)
		[self.websocket send:[self requestBodyForMethod:@"say" withParams:@{@"phrase": phrase}]];
}

- (void)skill:(NSString *)name {
	if (self.websocket.readyState == SR_OPEN)
		[self.websocket send:[self requestBodyForMethod:@"skill" withParams:@{@"name": name}]];
}

- (void)skill:(NSString *)name withArgs:(NSArray<NSString *> *)args {
	if (self.websocket.readyState == SR_OPEN)
		[self.websocket send:[self requestBodyForMethod:@"skill" withParams:@{@"name": name, @"args": args}]];
}

- (void)dialog:(NSString *)phrase {
	if (self.websocket.readyState == SR_OPEN)
		[self.websocket send:[self requestBodyForMethod:@"dialog" withParams:@{@"phrase": phrase}]];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
	NSLog(@"Connected to HeraldRPC");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message {
	NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
	NSLog(@"HeraldRPC response: %@", parsed);
	id result = parsed[@"result"];
	if ([result isKindOfClass:[NSDictionary class]]) {
		NSString *reply = result[@"reply"];
		if (reply != nil) {
			NSLog(@"REPLY %@", reply);
			[[HeraldRPC sharedInstance] say:reply];
		}
	}
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	NSLog(@"HeraldRPC closed: %@", reason);
	self.websocket = nil;
	[self connect];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"HeraldRPC failed: %@", error);
}

@end
