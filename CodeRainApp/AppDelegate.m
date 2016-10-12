//
//  AppDelegate.m
//  CodeRainApp
//
//  Created by Shuo Zhang on 2016/10/7.
//  Copyright © 2016年 Jon Showing. All rights reserved.
//

#import "AppDelegate.h"
#import "CodeRainView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) CodeRainView *rainView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    _rainView = [[CodeRainView alloc] initWithFrame:CGRectZero isPreview:NO];
    _rainView.frame = _window.contentView.bounds;
    _window.backgroundColor = [NSColor blackColor];
    [_window.contentView addSubview:_rainView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResize:) name:NSWindowDidResizeNotification object:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)didResize:(NSNotification *) notify{
    _rainView.frame = _window.contentView.bounds;
}


@end
