Pod::Spec.new do |s|
  s.name         = "STPopup"
  s.version      = "1.6.1"
  s.summary      = "STPopup provides STPopupController, which works just like UINavigationController in form sheet/bottom sheet style, for both iPhone and iPad."

  s.description  = <<-DESC
                    - Extend your view controller from UIViewController, build it in your familiar way.
                    - Push/Pop view controller in to/out of popup view stack, and set navigation items by using self.navigationItem.leftBarButtonItem and rightBarButtonItem, just like you are using UINavigationController.
                    - Support both "Form Sheet" and "Bottom Sheet" style.
                    - Work well with storyboard(including segue).
                    - Customize UI by using UIAppearance.
                    - Auto-reposition of popup view when keyboard is showing up, make sure your UITextField/UITextView won't be covered by the keyboard.
                    - Drag navigation bar to dismiss popup view.
                    - Support both portrait and landscape orientation, and both iPhone and iPad.
                    DESC

  s.homepage     = "https://github.com/kevin0571/STPopup"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kevin Lin" => "kevin_lyn@outlook.com" }

  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/kevin0571/STPopup.git", :tag => s.version }

  s.source_files = "STPopup/*.{h,m}"
  s.public_header_files = "STPopup/*.h"
end
