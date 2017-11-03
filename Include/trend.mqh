//+------------------------------------------------------------------+
//|                                                        trend.mqh |
//|                                  Copyright 2017, PHK Corporation |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://4xlots.com"
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
   UNKNOWN=3,
   BREAKOUT_UP=4,
   BREAKOUT_DOWN=5,
};

extern int PeriodLookback = 200;
extern int ADXPeriod = 20;
extern TrendStrength trendStrength=VeryStrong;

#import "trendlib.ex4"
   int TrendDirection();
   string TrendDescription(int trend_direction);
#import
//+------------------------------------------------------------------+
