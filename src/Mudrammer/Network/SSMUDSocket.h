@import Foundation;
#import "SSAttributedLineGroup.h"

@class SSMUDSocket;

@protocol SSMUDSocketDelegate <NSObject>

@required
- (BOOL) mudsocketShouldAttemptSSL:(SSMUDSocket *)socket;
- (void) mudsocket:(SSMUDSocket *)socket didReceiveAttributedLineGroup:(SSAttributedLineGroup *)group;

@optional
- (void) mudsocketDidConnectToHost:(SSMUDSocket *)socket;
- (void) mudsocket:(SSMUDSocket *)socket didDisconnectWithError:(NSError *)err;
- (void) mudsocket:(SSMUDSocket *)socket receivedMSSPData:(NSDictionary *)MSSPData;
- (void) mudsocket:(SSMUDSocket *)socket receivedGMCPModule:(NSString *)module data:(NSDictionary *)data;

@end
