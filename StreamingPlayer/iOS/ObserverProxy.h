#pragma once

#include <Uno/Uno.h>
#include <Foundation/Foundation.h>

@interface ObserverProxyImpl : NSObject

@property (copy) void (^callback)(id);

- (void)observeValueForKeyPath:(NSString *)
	keyPath
	ofObject:(id)object
	change:(NSDictionary *)change
	context:(void *)context;

@end
