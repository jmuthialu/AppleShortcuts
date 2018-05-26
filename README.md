# Accelerating App Interactions with Shortcuts

Make it easy for people to use Siri with your app by providing shortcuts to your app’s actions.

## Overview

Soup Chef is the fictitious app from this sample code project. The project shows you how to add shortcuts and personalized phrases to Siri. With shortcuts, users can access features of your app from places such as Spotlight search, Lock Screen, and Siri Watch Face. With phrases, users can speak to Siri to access your app's features. For example, a user of Soup Chef may order a bowl of clam chowder by saying to Siri, “Order clam chowder.”

## Get Started

Before you can run Soup Chef on your iPhone, you need to:

1. Set the app group name for the app and intent app extension targets to a valid name. For more information on app groups, see [Configure app groups](https://help.apple.com/xcode/mac/current/#/dev8dd3880fe).
2. Change `AppGroup` value in [`UserDefaults+DataSource.swift`](x-source-tag://app_group) to match your app group name.

## Project Structure

The Soup Chef project contains targets for the iPhone app and an Intent App Extension, which the system uses to handle shortcuts that run in the background. To avoid duplicating code that is common across the two targets, the project includes a shared framework called SoupKit. This framework provides a central location for shared code responsible for tasks such as data management and donating shortcuts.
For more information about structuring code, see [Structuring Your Code to Support App Extensions](https://developer.apple.com/documentation/sirikit/structuring_your_code_to_support_app_extensions).

## Define Shortcuts

Soup Chef has a key feature that people are likely to use frequently: ordering soup. To make it easy for users to place an order for soup, it makes sense for the app to add a shortcut for this feature for use with Siri. By adding the shortcut, Siri can make suggestions to the user based on their previous order history. For example, say the user likes to order tomato soup every Monday around noon. After placing this order a few times using Soup Chef, Siri learns the user’s pattern, and can use that information to predicate when the user might place a similar order. On the following Monday, Siri suggests to the user that they might want to order a bowl of tomato soup from Soup Chef.

## Custom Intent

To accomplish this, the app needs an `OrderSoup` intent. However, the system doesn’t provide this type of intent, so Soup Chef provides a custom intent.

You define a custom intent by first adding an *Intent Definition* file to your Xcode project. Then add the custom intent to the definition file. Soup Chef defines its custom intent as `OrderSoup`. The intent has three parameters:

- `soup`: The type of soup.
- `quantity`: The number of bowls of soup.
- `options`: Optionals toppings--such as cheese or croutons--to add to the soup.

Soup Chef uses the three parameters to define the different shortcut types. A shortcut type has a title, subtitle, and a set of parameter combinations such as:

- `soup` and `quantity`
- `soup` and `options`
- `soup`, `options`, and `quantity`

These types define the schema that Siri uses to identify requests the user makes; for example, “Order tomato soup with cheese.” The parameter combination for this example is: `soup` and `options`.

Soup Chef marks each shortcut types with Supports background execution; this way, the system doesn’t need to open the app to handle the intent. When marked this way, the system uses Soup Chef’s intent app extension to handle the order. This provides a better user experience because the user never leaves their current screen.

## Custom Response

The `OrderSoup` intent includes a set of custom responses that Siri shows to the user. Siri selects the response based on a code returned by intent extension when it confirms or handles the intent. For example, if the user orders a cup of chili and chili isn’t on the menu that day, the extension returns the `failureSoupUnavailable` code. Siri then responds to the user with “Sorry, we’re all out of chili.”

``` swift
if menuItem.isAvailable == false {
    //  Here's an example of how to use a custom response for a failure case when a particular soup item is unavailable.
    completion(OrderSoupIntentResponse.failureSoupUnavailable(soup: soup))
    return
}
```
[View in Source](x-source-tag://confirm_intent)

## Share the Intent

To use a custom intent in your app, Xcode needs to generate source code for the items defined in the *Intent Definition* file. However, for apps that have a shared framework, like Soup Chef, code generation should only happen for the framework target. Generating the code for the shared framework and app causes conflicts due to duplicated code.

To specify which target has the generated source code, use the *Intent Classes* setting in the Target Membership panel. For Soup Chef, only the SoupKit target uses the *Intent Classes* setting; all other targets use the *No Generated Classes* setting. And because SoupKit shares its code with other targets, the other targets can use the order soup intent.

## Donate Shortcuts

Before Siri can suggest shortcuts to the user, the app must tell Siri about the shortcuts through intent donations. An app makes a donation each time the user performs an action in the app. Soup Chef, for example, donates `OrderSoup` each time the user places an order through the app. Donating the intent each time the user places the order helps Siri learn about the user’s behavior, which helps Siri better predicate when the user may want to order soup again.

``` swift
private func donateInteraction(for order: Order) {
    let interaction = INInteraction(intent: order.intent, response: nil)
    interaction.donate { (error) in
        if error != nil {
            if let error = error as NSError? {
                os_log("Interaction donation failed: %@", log: OSLog.default, type: .error, error)
            }
        } else {
            os_log("Successfully donated interaction")
        }
    }
}
```
[View in Source](x-source-tag://donate_order)

- Note: Don’t donate intents handled by your Intent App Extension. Siri  already knows about those intents and will consider them when predicating suggestions in the future.

## Handle Shortcuts

As mentioned earlier, to handle a order soup intent, Soup Chef provides an Intent App Extension, which handles the intent in the background. This makes it possible for the user to remain on the current screen--such as the Lock Screen--while Soup Chef places the order in the background.

There are times, however, when the app must launch to handle the intent; for example, when the user taps the shortcut in Search. That’s why Soup Chef also handles the order soup intent in its [`application(_:continue:restorationHandler:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application) implementation found in the app delegate.

``` swift
func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let intent = userActivity.interaction?.intent as? OrderSoupIntent {
        handle(intent)
        return true
    } else if userActivity.activityType == NSUserActivity.viewMenuActivityType {
        handleUserActivity()
        return true
    }
    return false
}
```
[View in Source](x-source-tag://handle_in_app_delegate)

## Add Phrases to Siri

Ordering soup based on suggestions from Siri is a great start to expediting soup orders, but Soup Chef goes one step further by letting the user record a voice phrase for a particular order, and adding that phrase to Siri. Afterwards, the user can ask Siri to place the order by saying the phrase. For example, the user can add to Siri the phrase, “Clam chowder time,” for the shortcut that orders clam chowder with croutons. The next time the user craves clam chowder, they say to Siri, “Clam chowder time,” and Siri tells Soup Chef to place an order for clam chowder with croutons.

Users can record custom phrases in the Siri settings section of the Settings app on their iPhone or iPad. To make the experience better, however, Soup Chef provides the option to add the phrase directly from the app. From the order history, the user can tap a previous order to view its details. At the bottom of the order details is an Add to Siri button that, when tapped, lets the user record a new phrase. Soup Chef also provides a suggested phrase to help inspire the user.

``` swift
if let shortcut = INShortcut(intent: order.intent) {
    let addVoiceShortcutVC = INUIAddVoiceShortcutViewController(shortcut: shortcut)
    addVoiceShortcutVC.delegate = self
    present(addVoiceShortcutVC, animated: true, completion: nil)
}
```
[View in Source](x-source-tag://add_edit_phrases)

If a phrase already exists for the shortcut, the user can also change the phrase directly from Soup Chef.

``` swift
let editVoiceShortcutViewController = INUIEditVoiceShortcutViewController(voiceShortcut: shortcut)

editVoiceShortcutViewController.delegate = self
present(editVoiceShortcutViewController, animated: true, completion: nil)
```
[View in Source](x-source-tag://add_edit_phrases)

## More Information

Adding shortcuts and phrases are two examples of how your app can accelerate user interactions with Siri. For more information on how your app can leverage Siri, see the [SiriKit](https://developer.apple.com/documentation/sirikit) developer documentation.
