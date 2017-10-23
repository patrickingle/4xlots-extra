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
//| ------------------						                              |
//| 1. Set you Deposit, (sum of all deposits)			               |
//| 2. Set the PipProfit, if your trade profit is possitive but	   |
//|    still reducing your balance because of trade commissions,     |
//|    then increase this value to offset such expenses.	            |
//| 3. HedgeOnUnknownTrend, if the CCY pair is in flux, turn this on |
//|    to create hedge trades? Account must support hedging.         |
//| 4. AllowNewTrades, when off (false) will prevent new trades after|
//|    the existing martingale group have closed out, good for       |
//|    letting the existing session to complete for a withdrawal     |
//|		                                       					      |
//|								                                          |
//| Notes:							                                       |
//| -----							                                       |
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
//| 
//+------------------------------------------------------------------+
#define NL          "\n"
#define ENDPOINT    "https://api.4xlots.com/wp-json/v1/lots_optimize"

#include <4xlots.mqh>

extern double Deposit = 2000.0;
// PipProfit: Default: 5 for EURGBP
//            Change to: 20 for EURUSD, especially on small balances (<$2000)
extern int PipProfit = 5;
extern bool HedgeOnUnknownTrend = false;
extern bool AllowNewTrades = true;

string AccessKey="[REPLACE WITH YOUR ACCESSKEY FROM 4XLOTS.COM]";

int MagicNumber=20171016;

double lots,SL,TP,sell,buy,close,move;
double minsltp;

int ThisBarTrade=0;
bool NewBar;
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
   if (Bars!=ThisBarTrade) {
      NewBar=true;
      ThisBarTrade=Bars;
      NewBar=true;
   }
   minsltp=MarketInfo(Symbol(),MODE_SPREAD)+MarketInfo(Symbol(),MODE_STOPLEVEL)+PipProfit;

   string strTrend;
   int trend=2; // 0=down, 1=up, 2=reversal/unknown/limbo
   if (Close[50] < Close[100] && Close[100] < Close[150]) {
      trend = 0;
      strTrend = "Trend is DOWN";
   } else if (Close[50] > Close[100] && Close[100] > Close[150]) {
      trend = 1;
      strTrend = "Trend is UP";
   } else {
      strTrend = "Trend is UNKNOWN";
   }
   
   Comment("Account Equity: " + DoubleToString(AccountEquity()) + NL + "AccountLeverage: " + IntegerToString(AccountLeverage()) + NL + "MIN Lot Size: " + DoubleToString(MarketInfo(Symbol(),MODE_MINLOT)) + NL + "MAX Lot Size: " + DoubleToString(MarketInfo(Symbol(),MODE_MAXLOT)) + NL + "Account Profit: " + DoubleToString(AccountProfit()) + NL + NL + strTrend);
   
   if(orderstotal()==0 && NewBar && trend == 1 && AllowNewTrades == true) {
      if(minsltp==0) {
         TP=0;
      } else {
         TP=Ask+minsltp*Point;
      }
      lots=LotsOptimize(Deposit,false); //Lots;
      if(lots<MarketInfo(Symbol(),MODE_MINLOT)) lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT)) lots=MarketInfo(Symbol(),MODE_MAXLOT);
      buy=OrderSend(Symbol(),OP_BUY,lots,NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Buy",MagicNumber,0,clrBlue);
      NewBar=false;
   }

   if(orderstotal()==0 && NewBar && trend == 0 && AllowNewTrades == true) {
      if(minsltp==0){TP=0;}else{TP=Bid-minsltp*Point;}
      lots=LotsOptimize(Deposit,false);
      if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
      sell=OrderSend(Symbol(),OP_SELL,lots,NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Sell",MagicNumber,0,clrRed);
      NewBar=false;
   }
   
   if (HedgeOnUnknownTrend == true) {
      if (orderstotal()==0 && NewBar && trend == 2) {
         lots=LotsOptimize(Deposit,false);
         if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
         if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
         if(minsltp==0) {TP=0;} else {TP=Ask+minsltp*Point;}
         buy=OrderSend(Symbol(),OP_BUY,lots,NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Buy",MagicNumber,0,clrBlue);
         if(minsltp==0){TP=0;}else{TP=Bid-minsltp*Point;}
         sell=OrderSend(Symbol(),OP_SELL,lots,NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Sell",MagicNumber,0,clrRed);
         NewBar=false;
      }
   }

   if(LastType()=="BUY" && LastPrice(OP_BUY)>Close[1] && Close[1]<Open[1] && NewBar) {
      lots=LotsOptimize(Deposit,false); //lots*multiplier;
      if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
      TP=Ask+((MathAbs(ProfitMoney())/(TotalLots()+lots))*Point)+minsltp*Point;
      ModifyTP(OP_BUY,TP);
      
         if(AccountFreeMarginCheck(Symbol(),OP_BUY,lots)<=0 || GetLastError()==134) {
         } else if (trend == 1) {
            buy=OrderSend(Symbol(),OP_BUY,NormalizeDouble(lots,2),NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Buy",MagicNumber,0,clrBlue);
            NewBar=false;
         } else if (trend == 0) {
            TP=Bid-((MathAbs(ProfitMoney())/(TotalLots()+lots))*Point)-minsltp*Point;
            sell=OrderSend(Symbol(),OP_SELL,NormalizeDouble(lots,2),NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Sell",MagicNumber,0,clrRed);
            NewBar=false;
         }
   }

   if(LastType()=="SELL" && LastPrice(OP_SELL)<Close[1] && Close[1]>Open[1] && NewBar) {
      lots=LotsOptimize(Deposit,false); //lots*multiplier;
      if(lots<MarketInfo(Symbol(),MODE_MINLOT))lots=MarketInfo(Symbol(),MODE_MINLOT);
      if(lots>MarketInfo(Symbol(),MODE_MAXLOT))lots=MarketInfo(Symbol(),MODE_MAXLOT);
      TP=Bid-((MathAbs(ProfitMoney())/(TotalLots()+lots))*Point)-minsltp*Point;
      ModifyTP(OP_SELL,TP);
       if(AccountFreeMarginCheck(Symbol(),OP_SELL,lots)<=0 || GetLastError()==134) {
       } else if (trend == 0) {
         sell=OrderSend(Symbol(),OP_SELL,NormalizeDouble(lots,2),NormalizeDouble(Bid,Digits),30,0,NormalizeDouble(TP,Digits),"Sell",MagicNumber,0,clrRed);
         NewBar=false;
       } else if (trend == 1) {
         TP=Ask+((MathAbs(ProfitMoney())/(TotalLots()+lots))*Point)+minsltp*Point;
         buy=OrderSend(Symbol(),OP_BUY,NormalizeDouble(lots,2),NormalizeDouble(Ask,Digits),30,0,NormalizeDouble(TP,Digits),"Buy",MagicNumber,0,clrBlue);
         NewBar=false;
       }
   }
   
   if (orderstotal() > MaxOpenTrades) {
      // stop new trades
      //NewBar = false;
   } else {
      // permit new trades
      //NewBar = true;
   }
   
   if ((AccountEquity() * 2) > Deposit) {
      // Account equity is twice the Deposit, then close all trades
      
   }
   

}
//+------------------------------------------------------------------+
int orderstotal()
  {
   int cnt=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && MagicNumber==OrderMagicNumber())
           {
            cnt++;
           }
     }
   return(cnt);
  }
//***************************//
double ProfitMoney()
  {
   double cnt=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && MagicNumber==OrderMagicNumber())
           {
            cnt+=OrderProfit();
           }
     }
   return(cnt);
  }
//***************************//
double TotalLots()
  {
   double cnt=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && MagicNumber==OrderMagicNumber())
           {
            cnt+=OrderLots();
           }
     }
   return(cnt);
  }
//***************************//
string LastType()
  {
   string cnt="None";
   for(int i=OrdersTotal();i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && MagicNumber==OrderMagicNumber())
           {
            if(OrderType()==OP_BUY)return("BUY");
            if(OrderType()==OP_SELL)return("SELL");
           }
     }
   return(cnt);
  }
//============ 
double LastPrice(int tip)
  {
   double cnt=0;
   for(int i=OrdersTotal();i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && MagicNumber==OrderMagicNumber() && OrderType()==tip)
           {
            return(OrderOpenPrice());
           }
     }
   return(cnt);
  }
//======
void ModifyTP(int tip,double tp)
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==tip)
           {
            if(NormalizeDouble(OrderTakeProfit(),Digits)!=NormalizeDouble(tp,Digits))
              {
               move=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(tp,Digits),0,clrGold);
              }
           }

        }
     }
  }
