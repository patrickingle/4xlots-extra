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
//| 0=Down, 1=Up, 2=Unknown/Sideways, 3=Breakout-UP, 4=Breakout-DN   |
//+------------------------------------------------------------------+
int TrendDirection() export
{
   static int trend;
   
   double adx = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,0);
   double adx_dip = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,0);
   double adx_dim = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,0);
   
   if (adx > trendStrength) {
      // Retrieve Global Variable from Price Channel Indicator,
      //    SEE https://github.com/patrickingle/4xlots-extra/Indicators/Price Channel.mq4   
      double price_channel = GlobalVariableGet("MidPriceChannel");
      
      if (adx_dip > adx_dim && Close[PeriodLookback] < Close[0] && Close[0] > price_channel) {
         trend = 1;
      } else if (adx_dip < adx_dim && Close[PeriodLookback] > Close[0] && Close[0] < price_channel) {
         trend = 0;
      }
   } else {
      double stdev_band = GlobalVariableGet("StdDevBand");
      double lower_band = GlobalVariableGet("LowerBand");
      double upper_band = GlobalVariableGet("UpperBand");
      
      if (High[0] < lower_band || Low[0] < lower_band) {
         trend = 3;
      } else if (High[0] > upper_band || Low[0] > upper_band) {
         trend = 4;
      } else {
         trend = 2;
      }
   }
   
   return (trend);
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
      case 3: // breakout UP
         return ("Breakout on UP");
         break;
      case 4: // breakout DOWN
         return ("Breakout on DOWN");
         break;
   }
   return ("Trend is UNKNOWN");
}
//+------------------------------------------------------------------+
