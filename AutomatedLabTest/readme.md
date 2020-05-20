# PSFModule guidance

This is a finished module layout optimized for implementing the PSFramework.

If you don't care to deal with the details, this is what you need to do to get started seeing results:

 - Add the functions you want to publish to `/functions/`
 - Update the `FunctionsToExport` node in the module manifest (AutomatedLabTest.psd1). All functions you want to publish should be in a list.
 - Add internal helper functions the user should not see to `/internal/functions/`
 
 ## Path Warning
 
 > If you want your module to be compatible with Linux and MacOS, keep in mind that those OS are case sensitive for paths and files.
 
 `Import-ModuleFile` is preconfigured to resolve the path of the files specified, so it will reliably convert weird path notations the system can't handle.
 Content imported through that command thus need not mind the path separator.
 If you want to make sure your code too will survive OS-specific path notations, get used to using `Resolve-path` or the more powerful `Resolve-PSFPath`.