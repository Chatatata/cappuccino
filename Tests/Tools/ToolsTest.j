var OS = require("os");
var FILE = require("file");

function cleanup() {
    ["ToolsTestApp", "PressTestApp", "FlattenTestApp"].forEach(function(dir) {
        if (FILE.isDirectory(dir))
            FILE.rmtree(dir);
    });

    ["objj2objcskeletonTestFile.h", "objj2objcskeletonTestFile.m", "objj2objcskeletonTestFile.j", "objjWarningTestFile.j", "objjErrorTestFile.j"].forEach(function(file) {
        if (FILE.isFile(file))
            FILE.remove(file);
    });
}

@implementation ToolsTest : OJTestCase
{
}

- (void)setUp
{
    cleanup();
    FILE.write("objj2objcskeletonTestFile.j", "@import <Foundation/CPObject.j>\n@import <AppKit/AppKit.j>\n\n\n@implementation AppController : CPObject\n{\n    @outlet CPSplitView splitViewA;\n    @outlet CPSplitView splitViewB;\n    @outlet CPSplitView splitViewC;\n}\n\n@end");
    FILE.write("objjWarningTestFile.j", "@import <Foundation/Foundation.j>@implementation AppController : CPObject{CPWindow theWindow;}@end");
    FILE.write("objjErrorTestFile.j", "@implementation AppController : CPObject{}@end");
}

- (void)tearDown
{
    cleanup();
}

- (void)testTools
{
    var status,
        rootDirectory = FILE.cwd();

    status = OS.system(["capp", "gen", "ToolsTestApp"].map(OS.enquote).join(" ") + " > /dev/null");
    [self assert:0 equals:status message:"capp gen failed"];

    status = OS.system(["press", "-f", "ToolsTestApp", "PressTestApp"].map(OS.enquote).join(" ") + " > /dev/null");
    [self assert:0 equals:status message:"press failed"];

    status = OS.system(["flatten", "-f", "ToolsTestApp", "FlattenTestApp"].map(OS.enquote).join(" ") + " > /dev/null");
    [self assert:0 equals:status message:"flatten failed"];

    status = OS.system(["objj", "ToolsTestApp/AppController.j"]);
    [self assert:0 equals:status message:"objj failed"];

    status = OS.system(["objj", "-x", "ToolsTestApp/AppController.j"]);
    [self assert:0 equals:status message:"objj failed"];

    var p = OS.popen(["objj", "--xml", "objjErrorTestFile.j"]);
    [self assert:1 equals:p.wait() message:"objj failed"];
    [self assert:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version = \"1.0\"><array><dict><key>line</key><integer>1</integer><key>path</key><string>" + rootDirectory + "/objjErrorTestFile.j</string><key>message</key><string>Can&apos;t find superclass CPObject</string></dict></array></plist>\n" equals:p.stdout.read() message:"objj failed"];

    var p = OS.popen(["objj", "-x", "objjWarningTestFile.j"]);
    [self assert:0 equals:p.wait() message:"objj failed"];
    [self assert:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version = \"1.0\"><array><dict><key>line</key><integer>1</integer><key>path</key><string>" + rootDirectory + "/objjWarningTestFile.j</string><key>message</key><string>\n@import &lt;Foundation/Foundation.j&gt;@implementation AppController : CPObject{CPWindow theWindow;}@end\
\n                                                                                   ^\
\nWARNING line 1 in file:" + rootDirectory + "/objjWarningTestFile.j: Unknown type &apos;CPWindow&apos; for ivar &apos;theWindow&apos;</string></dict></array></plist>\n" equals:p.stdout.read() message:"objj failed"];

    status = OS.system(["objj", "-m", "ToolsTestApp/AppController.j", "ToolsTestApp/AppController.j"]);
    [self assert:0 equals:status message:"objj failed with several files"];

    status = OS.system(["objj", "-I", "ToolsTestApp/Frameworks", "ToolsTestApp/AppController.j"]);
    [self assert:0 equals:status message:"objj failed with options -I"];

    status = OS.system(["objj2objcskeleton", "objj2objcskeletonTestFile.j", "."]);
    [self assert:0 equals:status message:"objj2objcskeleton failed"];

    var contentHeader = FILE.read("objj2objcskeletonTestFile.h"),
        expectedHeaderResult = "#import <Cocoa/Cocoa.h>\n#import \"xcc_general_include.h\"\n\n@interface AppController : NSObject\n\n@property (assign) IBOutlet NSSplitView* splitViewA;\n@property (assign) IBOutlet NSSplitView* splitViewB;\n@property (assign) IBOutlet NSSplitView* splitViewC;\n\n@end\n";

    [self assert:contentHeader equals:expectedHeaderResult message:@"Header generated by objj2objcskeleton is wrong"];

    var contentMFile = FILE.read("objj2objcskeletonTestFile.m"),
        expectedMResult = "#import \"objj2objcskeletonTestFile.h\"\n\n@implementation AppController\n@end\n";

    [self assert:contentMFile equals:expectedMResult message:@"File generated by objj2objcskeleton is wrong"];
}

@end
