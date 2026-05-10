@import Foundation;
@import CoreGraphics;
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
// Pulled by the socket at connect time so the very first NAWS subnegotiation
// reflects the real cell-grid. Return CGSizeZero (or the default value) if
// the host hasn't been laid out yet.
- (CGSize) mudsocketCurrentCharSize:(SSMUDSocket *)socket;

@end
