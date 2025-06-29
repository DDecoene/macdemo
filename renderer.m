// [
//  project_bundle_2025-06-29_21-26-54-722.txt:
//  renderer.m
// ]
#import <Cocoa/Cocoa.h> // For NSApplication, NSWindow, NSMenu, etc.
#import <Metal/Metal.h> // For MTLDevice, MTLCommandQueue, etc.
#import <MetalKit/MetalKit.h> // For MTKView and MTKViewDelegate

// --- FIX: MyDelegate class definition is now at the top level ---
// This is a custom delegate for MTKView to handle drawing callbacks.
@interface MyDelegate : NSObject <MTKViewDelegate>
@end

@implementation MyDelegate
// This method is called by MTKView whenever it needs to draw a frame.
- (void)drawInMTKView:(nonnull MTKView *)view {
    // Declare the C function we will call to perform the actual drawing.
    // This function is defined in main.c.
    extern void frame_callback(void* layer);
    // Call the C function, passing the Metal layer from the view.
    frame_callback((__bridge void*)view.layer);
}

// This method is called when the view's drawable size changes (e.g., window resize).
// We don't need to do anything for this demo.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {}
@end
// --- End of delegate definition ---


// This function is called from main.c to bootstrap the macOS application.
// It sets up the window and the Metal view.
void start_app(void) {
    // Get the shared application instance.
    [NSApplication sharedApplication];
    // Set the application's activation policy (how it appears in the Dock, etc.).
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    // Create the application's menu bar.
    NSMenu *menubar = [NSMenu new];
    NSMenuItem *appMenuItem = [NSMenuItem new];
    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];

    // Create the "AppName" menu (typically found in the top-left).
    NSMenu *appMenu = [NSMenu new];
    // Get the process name to use in the menu item.
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSString *quitTitle = [@"Quit " stringByAppendingString:appName];
    // Create a menu item for quitting the application.
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                          action:@selector(terminate:) // Target method for quitting.
                                                   keyEquivalent:@"q"]; // Keyboard shortcut 'Q'.
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];

    // Define the window's initial frame (position and size).
    NSRect frame = NSMakeRect(0, 0, 800, 600); // Window will start at this size before going fullscreen.
    
    // Create the main application window.
    // MODIFIED: Added NSWindowStyleMaskResizable to allow fullscreen behavior.
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered // Use buffering for drawing.
                                                       defer:NO]; // Create the window immediately.
    // Center the window on the screen.
    [window center];
    // Set the window's title.
    [window setTitle: @"C + Metal Demo"];
    // Make the window visible and bring it to the front.
    [window makeKeyAndOrderFront:nil];
    
    // ADDED: Programmatically enter fullscreen mode.
    [window toggleFullScreen:nil];

    // Create a Metal device (represents the GPU).
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        // This should not happen on modern Macs, but good practice to check.
        NSLog(@"Metal is not supported on this device.");
        return;
    }

    // Create a MetalKit view. This view manages the Metal layer and handles resizing/drawing.
    MTKView *view = [[MTKView alloc] initWithFrame:frame device:device];
    // Set the pixel format for the view's drawable texture.
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // --- FIX: Retain the delegate object ---
    // Create an instance of our custom delegate and assign it to the view.
    // The delegate object is now strongly referenced by the 'delegate' property
    // of MTKView, so it won't be deallocated prematurely.
    MyDelegate *delegate = [[MyDelegate alloc] init];
    view.delegate = delegate;
    // --- END OF FIX ---

    // Set the view as the content of the window.
    window.contentView = view;

    // Activate the application and bring it to the foreground.
    [NSApp activateIgnoringOtherApps:YES];
    // Start the main run loop for the application. This is what keeps the app alive
    // and processes events (like drawing requests, window closing, etc.).
    [NSApp run];
}