//
//  AppDelegate.m
//  Dark Mode Switcher
//
//  Created by Colin Campbell on 3/2/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <NSMenuDelegate>
@property (weak) IBOutlet NSWindow *window;

// About
@property (nonatomic, retain) IBOutlet NSTextField *aboutLabel;

//  Menu
@property (nonatomic, retain) IBOutlet NSMenu *statusMenu;
@property (nonatomic, retain) IBOutlet NSMenuItem *enableDarkModeMenuItem;
@property (nonatomic, retain) IBOutlet NSMenuItem *openAtLoginMenuItem;

// Status
@property (strong, nonatomic) NSStatusItem *statusItem;

// Session properties
@property (assign, nonatomic) BOOL darkModeOn;
@property (assign, nonatomic) BOOL openAtLogin;

- (LSSharedFileListItemRef)itemRefInLoginItems;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Set the status menu
    self.statusItem.menu = self.statusMenu;
    
    // Set the version label
    self.aboutLabel.stringValue = [NSString stringWithFormat:@"Version %@ Build %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
}




// Getter methods

- (NSStatusItem *)statusItem {
    if (!_statusItem) {
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        [_statusItem setImage:[NSImage imageNamed:@"statusIcon"]];
        [_statusItem.image setTemplate:YES];
        _statusItem.highlightMode = YES;
    }
    return _statusItem;
}




// Instance methods

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef res = nil;
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    NSArray *loginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFErrorRef itemError;
        CFURLRef itemURLRef = LSSharedFileListItemCopyResolvedURL(itemRef, 0, &itemError);
        NSURL *itemURL = (__bridge NSURL *)itemURLRef;
        if ([itemURL isEqual:bundleURL]) {
            res = itemRef;
            break;
        }
    }
    
    if (res != nil) CFRetain(res);
    CFRelease(loginItemsRef);
    CFRelease((__bridge CFTypeRef)(loginItems));
    
    return res;
}




// Action methods

- (IBAction)enableDarkModeAction:(NSMenuItem *)item {
    if (self.darkModeOn) {
        self.darkModeOn = NO;
        self.enableDarkModeMenuItem.state = NSOffState;
        CFPreferencesSetValue((CFStringRef)@"AppleInterfaceStyle", NULL, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    }
    else {
        self.darkModeOn = YES;
        self.enableDarkModeMenuItem.state = NSOnState;
        CFPreferencesSetValue((CFStringRef)@"AppleInterfaceStyle", @"Dark", kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)@"AppleInterfaceThemeChangedNotification", NULL, NULL, YES);
    });
}

- (IBAction)openAtLoginAction:(NSMenuItem *)item {
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    
    if (self.openAtLogin) {
        self.openAtLogin = NO;
        self.openAtLoginMenuItem.state = NSOffState;
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        
        if (itemRef != nil) {
            LSSharedFileListItemRemove(loginItemsRef,itemRef);
            CFRelease(itemRef);
        }
    }
    else {
        self.openAtLogin = YES;
        self.openAtLoginMenuItem.state = NSOnState;
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    
    CFRelease(loginItemsRef);
}

- (IBAction)quitAction:(NSMenuItem *)item {
    [[NSApplication sharedApplication] terminate:self];
}




// NSMenuDelegate methods

- (void)menuWillOpen:(NSMenu *)menu {
    NSString *value = (__bridge NSString *)(CFPreferencesCopyValue((CFStringRef)@"AppleInterfaceStyle", kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost));
    if ([value isEqualToString:@"Dark"]) {
        self.darkModeOn = YES;
        self.enableDarkModeMenuItem.state = NSOnState;
    }
    else {
        self.darkModeOn = NO;
        self.enableDarkModeMenuItem.state = NSOffState;
    }
    
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    if (itemRef != nil) {
        self.openAtLogin = YES;
        self.openAtLoginMenuItem.state = NSOnState;
        CFRelease(itemRef);
    }
    else {
        self.openAtLogin = NO;
        self.openAtLoginMenuItem.state = NSOffState;
    }
}

@end
