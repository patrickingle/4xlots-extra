//+------------------------------------------------------------------+
//|                                            Martingale_Profit.mq4 |
//|                                            phkcorp2005@gmail.com |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property copyright "PHK Corporation"
#property link      "https://4xlots.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Usage Instructions:                                              |
//| ------------------						     |
//| 1. Set you Deposit, (sum of all deposits)			     |
//| 2. Set the PipProfit, if your trade profit is possitive but	     |
//|    still reducing your balance because of trade commissions,     |
//|    then increase this value to offset such expenses.	     |
//| 3. HedgeOnUnknownTrend, if the CCY pair is in flux, turn this on |
//|    to create hedge trades? Account must support hedging.         |
//| 4. AllowNewTrades, when off (false) will prevent new trades after|
//|    the existing martingale group have closed out, good for       |
//|    letting the existing session to complete for a withdrawal     |
//|		                                                     |
//|								     |
//| Notes:							     |
//| -----							     |
//| During testing, a demo account was created with a leverage       |
//| of 1000:1 and an initial deposit of $110 but then increased      |
//| periodically, and the currency pair EURGBP is being traded       |
//| on a M1 chart. Hence a minimum deposit of $2000 is required to   |
//| use this Expert Advisor.                                         |
//|                                                                  |
//| Live Testing:                                                    |
//| ------------                                                     |
//| Performed on a TW account with a leverage at 200:1 with an       |
//| initial deposit of $200 produce an average of $10 profit per day.|
//| The new margin level check prevented a castrophic margin call    |
//| giving back acceptable profits. Unlike the Demo testing,         |
//| additional deposits were not needed.                             |
//|                                                                  |
//| Simulated Testing:                                               |
//| -----------------                                                |
//| On the $200 demo account with 1000:1, grew the account quicker,  |
//| to where it double every two days, but had to keep add additional|
//| funds to the demo account (a nice feature of Traderways--to add  |
//| additional funds to a Demo account from your Traderways Private  |
//| Office) when the margin level drop below 200%.                   |
//|                                                                  |
//| MarginLevelMin: 
//| --------------
//| The Margin Level is an Account indicator when the account is at
//| risk for a margin call and not monitoring this parameter
//| is why so many Expert Advisors fail. When the Margin Level drops
//| to 200%, it means you have too many trades opened.
//| The MarginLevelMin parameter is our fail safe which is set higher
//| than 200, and if we see the Margin Level drop below the
//| MarginLevelMin value, we are going to proactively start closing
//| out positive trades (those with a profit) until the Margin Level
//| rises above this value. This use to be a manual operation, but
//| now is automated. 
//| 
//| MaxLossForceClose: (Always a negative value)
//| -----------------
//| When there are no positive or in the profit trades to close out
//| in order to restore the Margin Level to a safe level, we need to
//| start closing out some negative trades. This is the value of the
//| loss that is acceptable. Giving back some profits without giving
//| back all profits and your principal.
//| 
//| Updates
//| -------
//| With the updated trend library validating a trend using three
//| indicators had made this a safer Martingale by only trading on a
//| confirm trend. Sideways and Breakouts will not be trade sessions.
//|
//| Live Testing
//| ------------
//| On a Tradersway ECN account with 200:1 Leverage and a deposit
//| of $100 on both the EURUSD and EURGDP on the M1 chart. The results
//| stop the crazy Martingale trades and only on a Strong trend to
//| produce a $2 average daily profit. 
//+------------------------------------------------------------------+
#define NL          "\n"

#include <4xlots.mqh>
#include <margin-protect.mqh>
#include <trend.mqh>

extern int BarPosition = 20;
// PipProfit: Default: 5 for EURGBP
//            Change to: 20 for EURUSD, especially on small balances (<$2000)
extern int PipProfit = 5;
// minimum margin level before closing positive trades, when this falls to 200, a margin call is at risk
extern double MarginLevelMin = 300;
// maximum loss per trade user will tolertate if force close out negative trades to restore margin level to a safe leve
extern double MaxLossForceClose = -1.00;
extern bool HedgeOnUnknownTrend = false;
extern bool AllowNewTrades = true;


int MagicNumber=20171016;

double lots,SL,TP,sell,buy,close,move;
double minsltp;

int ThisBarTrade=0;
bool NewBar;

double MarginLevel;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
// Minumum SL & TP value computed as the sum of SL+TP+1
   minsltp=MarketInfo(Symbol(),MODE_SPREAD)+MarketInfo(Symbol(),MODE_STOPLEVEL)+PipProfit;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   static int previous_trend = 0;
   
   if (Bars!=ThisBarTrade) {
      // Get the last Trade Bar
      ThisBarTrade=Bars;
      // This is a NewBar that ha not been tested/traded
      NewBar=true;
   }
   minsltp=MarketInfo(Symbol(),MODE_SPREAD)+MarketInfo(Symbol(),MODE_STOPLEVEL)+PipProfit;

   string strTrend;
   static int trend=2; // 0=down, 1=up, 2=reversal/unknown/limbo

   trend = TrendDirection();
   strTrend = TrendDescription(trend);
   
   if (trend == 2) {
      NewBar=false;
   } else if (trend == 3) {
      NewBar=false;
   } else if (trend == 4) {
      NewBar=false;
   }
   
   
   // if the trend change, then close opened positive orders and take your profit
   if (trend != previous_trend) {
      Print("Trend change, closing out positive trades");
      previous_trend = trend;
      CloseOpenOrders(false);
   }
      
   Comment( "Account Equity: " + DoubleToString(AccountEquity()) + NL + "AccountLeverage: " + IntegerToString(AccountLeverage()) + NL + "MIN Lot Size: " + DoubleToString(MarketInfo(Symbol(),MODE_MINLOT)) + NL + "MAX Lot Size: " + DoubleToString(MarketInfo(Symbol(),MODE_MAXLOT)) + NL + "Account Profit: " + DoubleToString(AccountProfit()) + NL + NL + strTrend);

   // Check MarginLevel when there are trades?
   static bool notified_margin_level_low = false;
   static bool notified_margin_level_safe = false;
   if (AccountMargin() > 0) {
      MarginLevel = CalculateMarginLevel();
      if (MarginLevel <= MarginLevelMin) {
         if (notified_margin_level_low == false) {
            Print("Margin Level is below minimum threshold");
            notified_margin_level_low = true;
            notified_margin_level_safe = false;
         }
         AllowNewTrades = false;
         TP = RestoreSafeMarginLevel("Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,TP,minsltp,lots);
      } else {
         if (notified_margin_level_safe == false) {
            Print("Margin Level back at SAFE levels");
            notified_margin_level_safe = true;
            notified_margin_level_low = false;
         }
         AllowNewTrades = true;
      }
   }
   
   // Auto Adjust MaxLossForceClose to be 10% of the AccountProfit, e.g. if AP=1.98, then MaxLossForceClose=-0.19
   double adjMaxLossForceClose = (MathAbs(AccountProfit()) / 10) * -1;
   if (adjMaxLossForceClose < MaxLossForceClose) {
      MaxLossForceClose = adjMaxLossForceClose;
   }
   
   
   if(TotalOrders(MagicNumber)==0 && NewBar && trend == 1 && AllowNewTrades == true) {
      if(minsltp==0) {
         TP=0;
      } else {
         TP=Ask+minsltp*Point;
      }
      lots=LotsOptimize(Deposit,false); //Lots;
      if(lots<MarketInfo(Symbol(),MODE_MINLOT)) lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT)) lots=MarketInfo(Symbol(),MODE_MAXLOT);
      buy=OrderSend(Symbol(),OP_BUY,lots,NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrBlue);
      NewBar=false;
   }

   if(TotalOrders(MagicNumber)==0 && NewBar && trend == 0 && AllowNewTrades == true) {
      if (minsltp==0) {
         TP=0;
      } else{
         TP=Bid-minsltp*Point;
      }
      lots=LotsOptimize(Deposit,false);
      if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
      sell=OrderSend(Symbol(),OP_SELL,lots,NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrRed);
      NewBar=false;
   }
   
   if (HedgeOnUnknownTrend == true) {
      if (TotalOrders(MagicNumber)==0 && trend == 2) {
         lots=LotsOptimize(Deposit,false);
         if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
         if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
         if(minsltp==0) {TP=0;} else {TP=Ask+minsltp*Point;}
         buy=OrderSend(Symbol(),OP_BUY,lots,NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrBlue);
         if(minsltp==0){TP=0;}else{TP=Bid-minsltp*Point;}
         sell=OrderSend(Symbol(),OP_SELL,lots,NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrRed);
         //NewBar=false;
      }
   }

   if(LastPrice(OP_BUY, MagicNumber)>Close[1] && Close[1]<Open[1] && NewBar) {
      lots=LotsOptimize(Deposit,false); //lots*multiplier;
      if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
      TP=Ask+((MathAbs(ProfitMoney(MagicNumber))/(TotalLots(MagicNumber)+lots))*Point)+minsltp*Point;
      ModifyTP(OP_BUY,TP,MagicNumber);
      if(AccountFreeMarginCheck(Symbol(),OP_BUY,lots)<=0 || GetLastError()==134 || AllowNewTrades == false) {
      } else if (trend == 1) {
         buy=OrderSend(Symbol(),OP_BUY,NormalizeDouble(lots,2),NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrBlue);
      } else if (trend == 0) {
         TP=Bid-((MathAbs(ProfitMoney(MagicNumber))/(TotalLots(MagicNumber)+lots))*Point)-minsltp*Point;
         sell=OrderSend(Symbol(),OP_SELL,NormalizeDouble(lots,2),NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrRed);
      }
      NewBar = false;
   }

   if(LastPrice(OP_SELL,MagicNumber)<Close[1] && Close[1]>Open[1] && NewBar) {
      lots=LotsOptimize(Deposit,false); //lots*multiplier;
      if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
      TP=Bid-((MathAbs(ProfitMoney(MagicNumber))/(TotalLots(MagicNumber)+lots))*Point)-minsltp*Point;
      ModifyTP(OP_SELL,TP,MagicNumber);
       if(AccountFreeMarginCheck(Symbol(),OP_SELL,lots)<=0 || GetLastError()==134 || AllowNewTrades == false) {
       } else if (trend == 0) {
         sell=OrderSend(Symbol(),OP_SELL,NormalizeDouble(lots,2),NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrRed);
       } else if (trend == 1) {
         TP=Ask+((MathAbs(ProfitMoney(MagicNumber))/(TotalLots(MagicNumber)+lots))*Point)+minsltp*Point;
         buy=OrderSend(Symbol(),OP_BUY,NormalizeDouble(lots,2),NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Martingale Profit-"+IntegerToString(__LINE__),MagicNumber,0,clrBlue);
       }
       NewBar=false;
   }
   
}
//+------------------------------------------------------------------+
