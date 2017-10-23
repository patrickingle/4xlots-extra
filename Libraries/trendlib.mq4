//+------------------------------------------------------------------+
//|                                                     trendlib.mq4 |
//|                                  Copyright 2017, PHK Corporation |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://4xlots.com"
#property version   "1.00"
#property strict

#include <trend.mqh>

/*
 * ADX > 25 => in a trend
 * ADX.DI+ > ADX.DI- => Up Trend
 * ADX.DI+ < ADX.DI- => Down Trend
 * 
 * ADX Value 	Trend Strength
 * ---------   --------------
 * 0-25 	      Absent or Weak Trend
 * 25-50 	   Strong Trend
 * 50-75 	   Very Strong Trend
 * 75-100 	   Extremely Strong Trend
 * 
 */

//+------------------------------------------------------------------+
//| TrendDirection                                                   |
//| 0=Down, 1=Up, 2=Unknown/Sideways                                 |
//+------------------------------------------------------------------+
int TrendDirection() export
{
   double adx = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,0);
   double adx_dip = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,0);
   double adx_dim = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,0);

   // Retrieve Global Variable from Price Channel Indicator,
   //    SEE https://github.com/patrickingle/4xlots-extra/Indicators/Price Channel.mq4   
   double price_channel = GlobalVariableGet("MidPriceChannel");

   if (adx > trendStrength) {
      if (adx_dip > adx_dim && Close[PeriodLookback] < Close[0] && Close[0] > price_channel) {
         return (1);
      } else if (adx_dip < adx_dim && Close[PeriodLookback] > Close[0] && Close[0] < price_channel) {
         return (0);
      }
   }

   return (2);
}

//+------------------------------------------------------------------+
//| TrendDescription                                                 |
//+------------------------------------------------------------------+
string TrendDescription(int trend_direction) export
{
   switch(trend_direction) {
      case 0: // Down
         return ("Trend is DOWN");
         break;
      case 1: // Up
         return ("Trend is UP");
         break;
      case 2: // Unknown
         return ("Trend is UNKNOWN");
         break;
   }
   return ("Trend is UNKNOWN");
}
//+------------------------------------------------------------------+
