#include "iOS/ObserverProxy.h"

@implementation ObserverProxyImpl
- (void)observeValueForKeyPath:(NSString *)
	keyPath
	ofObject:(id)object
	change:(NSDictionary *)change
	context:(void *)context
{
	[self callback](keyPath);
}
@end
