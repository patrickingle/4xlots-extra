# 4xlots-extra
Extra files for use with 4xlots Forex RIsk Management Web Service, see https://4xlots.com for more information

# Relevance List of Files

    Libraries/4xlotslib.mq4 = the library for 4xlots REST API
    Libraries/marginprotectlib.mq4 = useful functions for checking margin level percentage, <200% risks margin call)
    Libraries/trailingstop.mq4 = functions to automatically add trailing stops to an open trade
    Libraries/trendlib.mq4 = trending functions using multiple indicators to detect and confirm a trend,

    Indicators/Bands.mq4 = modified indicator with Global parameters used by the trendlib.mq4
    Indicators/Price Channel.mq4 = modified indicator with Global parameters used by the trendlib.mq4
    
# Get Access to the 4xlots.com API for FREE!

When you open a Live account at Traderways using the IB link https://www.tradersway.com/?ib=1004584,

your will receive FREE access to the api.4xlots.com API.

To begin,

1. Create a Live account on Tradersway using the link https://www.tradersway.com/?ib=1004584

2. The visit https://4xlots.com and register for access using your email and providing your new Tradersway account
number only.

3. Confirm the registration email from Mailchimp.

4. You will receive a confirmation email with API active status.

5. Begin using 4xlots API is your Expert Advisors or other Forex trading algorithms

# Results

File: <a href="Results/Demo/DetailedStatement.pdf">Results/Demo/DetailedStatement.pdf</a>

>A very aggressive Martingale EA was acquired and I like the strategy that this EA was using but the original developer
>didn't include much thought in Risk Management specifically lots size and margin level detection that 
>scales as the equity and leverage changes. I implemented 4xlots web service, initially using the new WebRequest
>method but than falling back on the wininet library. Over the last month, I discovered issues that
>could potentially wipe out the account and did which is why you see extra deposits, and these changes
>are included in the source code at https://github.com/patrickingle/4xlots-extra/.

>My development methodology is to test as if I am trading with real money, that is start with an actual
>deposit amount. When test results are satisfactory, live testing proceeds. 

**ONLY USE DISCRETIONARY INCOME THAT YOU CAN AFFORD TO LOOSE AND DON'T ACT GREEDY!**

_Forex will return better than expected returns, and from these returns, you can further fund
an equity retirement account (after taxes are paid)._


# Publication

The following publication, "Using the 4XLots Web Service: A tool for risk management in forex trading" available on
Amazon at http://www.amazon.com/dp/B00D4765AU shows how to implement 4XLots API in your own Expert Advisor.

<img src="Images/B00D4765AU.jpg">

