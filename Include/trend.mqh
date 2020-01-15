//+------------------------------------------------------------------+
//|                                                        trend.mqh |
//|   Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://4xlots.com"
#property version   "1.01"
#property strict

enum TrendStrength
{
   Strong=25,
   VeryStrong=50,
   ExtemelyStrong=75,
};

enum Trend 
{
   DOWN=0,
   UP=1,
   SIDEWAYS=2,
   BREAKOUT_UP=3,       // The trend was in a sideways and switch to an up trend
   BREAKOUT_DOWN=4,     // The trend was in a sideways and switch to a down tremd
   COUNTER_UP=5,        // The trend was in an up trend or sideways and switch to a down trend
   COUNTER_DOWN=6,      // The trend was in a down trend or sideways and switch to an up trend
};

extern int PeriodLookback = 200;
extern int ADXPeriod = 20;
extern TrendStrength trendStrength=Strong;

#import "trendlib.ex4"
   Trend TrendDirection();
   string TrendDescription(Trend direction);
#import
//+------------------------------------------------------------------+
