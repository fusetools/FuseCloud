using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace SafariViewController
{

	[Require("Xcode.Framework", "SafariServices")]
	[ForeignInclude(Language.ObjC, "AVFoundation/AVFoundation.h")]
	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "SafariServices/SafariServices.h")]
	public extern(iOS) class Safari
	{
		[Foreign(Language.ObjC)]
		public static void PresentSafari(string url)
		@{
			NSURL* u = [[NSURL alloc] initWithString: url];
			SFSafariViewController* vc = [[SFSafariViewController alloc] initWithURL: u entersReaderIfAvailable:NO];
			[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:vc animated:YES completion:nil];
		@}

		[Foreign(Language.ObjC)]
		public static void DismissSafari()
		@{
			[[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
		@}
	}

	public interface ISafariViewController
	{
		void OpenUrl(string url);
		void Close();
	}
		

	[UXGlobalModule]
	public class SafariViewController : NativeModule
	{
		static SafariViewController _instance;

		ISafariViewController _svc;

		public SafariViewController()
		{
			if (_instance != null)
				return;

			_instance = this;
			Resource.SetGlobalKey(_instance, "SafariViewController");

			AddMember(new NativeFunction("openUrl", (NativeCallback)OpenUrl));
			AddMember(new NativeFunction("close", (NativeCallback)Close));

			if defined(iOS)
			{
				_svc = new SafariViewControlleriOSImpl();
			}
		}

		object[] OpenUrl(Context c, object[] args)
		{
			var url = args.ValueOrDefault<string>(0,"");
			if (url == "")
				throw new Exception("You need to supply a valid url");
			_svc.OpenUrl(url);
			return null;
		}

		object[] Close(Context c, object[] args) {
			_svc.Close();
			return null;
		}
	}

	extern(iOS) class SafariViewControlleriOSImpl : ISafariViewController
	{

		public void OpenUrl(string url)
		{
			debug_log("We are calling present safari with url: " + url);
			Safari.PresentSafari(url);
		}

		public void Close()
		{
			Safari.DismissSafari();
		}
	}
}
