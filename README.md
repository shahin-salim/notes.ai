# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

for puasing invoices:
https://docs.stripe.com/billing/subscriptions/pause-payment#collect-payment-never

To planmanagement use lookup key in stripe.

fields in workpsace
- subscription
- current_period_end: current_period_end
- current_period_start: current_period_start
- plan
- addons
- customer

Billing Model
- subscription
- current_period_end: current_period_end
- current_period_start: current_period_start
- plan
- addons
- customer
- status

invocies
--------
• Date of the invoice
• Invoice link
• Amount
• Download link
• Invoice status

- every price we we will give lookup key and fetch from stripe when requried and give to to the subscription method.

Stripe feild mappting
our fields -         stripe fields
next_renewal_date -  current_period_start
subscription_id -    subscription
plan -               prices
addons -             items
status -             status


amount, billing period, coupens




10
to make a invoice void use this stripe api: [text](https://docs.stripe.com/api/invoices/void)
we will run a celery task every hour and check for the user is there unpaid unvoice for an items in addon.
If found and not paid until now we will make the invoice void.
* this will not take effect on adding the addon into next subscription
- If already added into next subscription invoice how do we handle that also comes under manual resolution ?

in a day there can be multiple retry. so in that case we can set it to 3 days or 3 retries. 3 retry is better.

9
we create a hook using the hook only we will confirm the status change of subscription

12
we will have the invoices user have in invoice table. we will run the celery task for check all those invoices status.

because we have price table we don't need price id fetch as extra