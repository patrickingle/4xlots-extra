//+------------------------------------------------------------------+
//|                                                     trendlib.mq4 |
//|   Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://4xlots.com"
#property version   "1.01"
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
 // Trends: UP, DOWN, SIDEWAYS, BREAKOUT, COUNTER, PULLBACK
 
 // Phases of a Trade: Consolidation, Accumulation, Distribution, Participation (or Public Participation)

//+----------------------------------------------------------------------------------------------+
//| TrendDirection                                                                               |
//| 0=Down, 1=Up, 2=Unknown/Sideways, 3=Breakout-UP, 4=Breakout-DN, 5=Counter-UP, 6=Counter-DN   |
//+----------------------------------------------------------------------------------------------+
Trend TrendDirection() export
{
   static Trend trend = UNKNOWN;
   
   double adx = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,0);
   double adx_dip = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,0);
   double adx_dim = iADX(Symbol(),0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,0);
   double ma200 = iMA(Symbol(),0,200,PRICE_CLOSE,MODE_SMA,PRICE_CLOSE,0);
   double ma10 = iMA(Symbol(),0,10,PRICE_CLOSE,MODE_SMA,PRICE_CLOSE,0);
   double ma30 = iMA(Symbol(),0,30,PRICE_CLOSE,MODE_SMA,PRICE_CLOSE,0);
   double ma3 = iMA(Symbol(),0,3,PRICE_CLOSE,MODE_SMA,PRICE_CLOSE,0);
   double rsi = iRSI(Symbol(),0,14,PRICE_CLOSE,0);  // when RSI>70, indicates DOWNTREND consistently
   double momentum = iMomentum(Symbol(),0,30,PRICE_CLOSE,0); // >100 = UP, <99.95 = DOWN
   
   double osc = ma3 - ma10;
   
   double dpv = GlobalVariableGet("DPV");
   double fpv = GlobalVariableGet("FPV");
   double r1 = GlobalVariableGet("R1");
   double r2 = GlobalVariableGet("R2");
   double r3 = GlobalVariableGet("R3");
   double r4 = GlobalVariableGet("R4");
   double r5 = GlobalVariableGet("R5");
   double s1 = GlobalVariableGet("S1");
   double s2 = GlobalVariableGet("S2");
   double s3 = GlobalVariableGet("S3");
   double s4 = GlobalVariableGet("S4");
   double s5 = GlobalVariableGet("S5");
   
   // adx > 25 = Strong Trend
   // adx > 50 = Very Strong Trend
   // adx > 75 = Extreme;y Strong Trend
   if (adx > trendStrength) {
      // Retrieve Global Variable from Price Channel Indicator,
      //    SEE https://github.com/patrickingle/4xlots-extra/Indicators/Price Channel.mq4   
      double price_channel = GlobalVariableGet("MidPriceChannel");
      
      if (adx_dip > adx_dim && Close[PeriodLookback] < Close[0] && Close[0] > price_channel) {
         // Up Trend, when ADX+ > ADX-, Last Close > Lookback Close, Last Close > MidPriceChannel
         if (ma200 > Close[0] && ma10 > ma30) {
            // Confirmation of UP Trend, MA(200) > Last Close, MA(10) > MA(30)
            trend = UP;
         } else if (ma200 < Close[0] && ma10 < ma30 && rsi > 70) {
            trend = DOWN;
         }
      } else if (adx_dip < adx_dim && Close[PeriodLookback] > Close[0] && Close[0] < price_channel) {
         if (ma200 < Close[0] && ma10 < ma30 && rsi > 70) {
            trend = DOWN;
         } else if (ma200 > Close[0] && ma10 > ma30) {
            trend = UP;
         }
      }
      // OSC<0 while TREND=UP then TREND=COUNTER_DOWN
      // OSC>0 while TREND=DOWN then TREND=COUNTER_UP
      // OSC<0 while TREND=DOWN confirms TREND=DOWN
      // OSC>0 while TREND=UP confirms TREND=UP
      if (osc < 0 && trend == UP) {
         trend = COUNTER_DOWN;
      } else if (osc > 0 && trend == DOWN) {
         trend = COUNTER_UP;
      }
   } else {
      double stdev_band = GlobalVariableGet("StdDevBand");
      double lower_band = GlobalVariableGet("LowerBand");
      double upper_band = GlobalVariableGet("UpperBand");
            
      if ((High[0] < lower_band || Low[0] < lower_band) && momentum < 99.95) {
         if (Close[0] < dpv || Close[0] < s1) {
            trend = BREAKOUT_DOWN;
         } else if (Close[0] > dpv || Close[0] > r1) {
            trend = COUNTER_UP;
         }
      } else if ((High[0] > upper_band || Low[0] > upper_band) && momentum > 100) {
         if (Close[0] > dpv || Close[0] > r1) {
            trend = BREAKOUT_UP;
         } else if (Close[0] < dpv || Close[0] < s1) {
            trend = BREAKOUT_DOWN;
         }
      } else if (rsi > 70) {
         trend = DOWN;
      } else {
         if (Close[0] < s1) {
            trend = DOWN;
         } else if (Close[0] > r1) {
            trend = UP;
         } else {
            trend = SIDEWAYS;
         }
      }
      // OSC<0 while TREND=UP then TREND=COUNTER_DOWN
      // OSC>0 while TREND=DOWN then TREND=COUNTER_UP
      // OSC<0 while TREND=DOWN confirms TREND=DOWN
      // OSC>0 while TREND=UP confirms TREND=UP
      if (osc < 0 && (trend == BREAKOUT_UP || trend == SIDEWAYS)) {
         trend = COUNTER_DOWN;
      } else if (osc > 0 && (trend == BREAKOUT_DOWN || trend == SIDEWAYS)) {
         trend = COUNTER_UP;
      }
   }
   
   return (trend);
}

//+------------------------------------------------------------------+
//| TrendDescription                                                 |
//+------------------------------------------------------------------+
string TrendDescription(Trend direction) export
{
   switch(direction) {
      case DOWN:
         return ("Trend is DOWN");
         break;
      case UP:
         return ("Trend is UP");
         break;
      case SIDEWAYS:
         return ("Trend is SIDEWAYS");
         break;
      case BREAKOUT_UP:
         return ("Breakout on UP");
         break;
      case BREAKOUT_DOWN:
         return ("Breakout on DOWN");
         break;
      case COUNTER_DOWN:
         return ("Counter on DOWN");
         break;
      case COUNTER_UP:
         return ("Counter on UP");
         break;
   }
   return ("Trend is UNKNOWN");
}
//+------------------------------------------------------------------+
