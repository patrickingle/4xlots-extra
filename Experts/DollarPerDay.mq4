//+------------------------------------------------------------------+
//|                                                 DollarPerDay.mq4 |
//|                                  Copyright 2017, PHK Corporation |
//|                                           https://www.4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://www.4xlots.com"
#property version   "1.00"
#property strict

#include <4xlots.mqh>
#include <trend.mqh>
#include <margin-protect.mqh>

extern bool AllowNewTrades = true;
extern double Profit = 1.00;
extern int PipProfit = 10;

double MarginLevel = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   
   trendStrength = VeryStrong;
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static Trend trend=UNKNOWN; // 0=down, 1=up, 2=reversal/unknown/limbo
   double profit = Profit;

   if (OrdersTotal() == 0 && AllowNewTrades == true) {
      trend = TrendDirection();
      
      double lots = LotsOptimize(Deposit, false);
      Print("Lots=",lots);
      if (lots == 0.0) {
         lots = MarketInfo(Symbol(),MODE_MINLOT);
      }
      double tp = 0.0;
      int ticket = 0;
      
   
      switch (trend) {
         case DOWN:
            ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,0,0.0,0.0,"Open Sell Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()-(TP * 100 * Point),Digits),0) == true) {
                  }
               }
               // Don't permit new trades once there is an open trade
               AllowNewTrades = false;
            }
            break;
         case UP:
            ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,0,0.0,0.0,"Open Buy Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()+(TP * 100 * Point),Digits),0) == true) {
                  }
               }
               // Don't permit new trades once there is an open trade
               AllowNewTrades = false;
            }
            break;
         case BREAKOUT_DOWN:
            ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,0,0.0,0.0,"Open Breakout Buy Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()+(TP * 100 * Point),Digits),0) == true) {
                  }
               }
               // Don't permit new trades once there is an open trade
               AllowNewTrades = false;
            }
            break;
         case BREAKOUT_UP:
            ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,0,0.0,0.0,"Open Breakout Sell Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()-(TP * 100 * Point),Digits),0) == true) {
                  }
               }
               // Don't permit new trades once there is an open trade
               AllowNewTrades = false;
            }
            break;
         case UNKNOWN: // Also a sideways market
            break;
      }
   } else {
      // There are open orders
      // As long as there are open trades, we will always check for our minimum profit has been met or breached?
      for (int i=0; i < OrdersTotal(); i++) {
         if (OrderSelect(i,SELECT_BY_POS)== true) {
            if (OrderSymbol() == Symbol()) {
               // Default minimum profit is $1 over costs(commission) plus swap
               double minProfit = profit + MathAbs(OrderCommission()) + MathAbs(OrderSwap());
               if (OrderComment() == "Open Sell Order") {
                  if (trend == UP || trend == BREAKOUT_UP) {
                     // Trend reverse during an open trade, desire to close in Profit ASAP
                     minProfit = MathAbs(OrderCommission()) + MathAbs(OrderSwap());
                  }
               } else if (OrderComment() == "Open Buy Order") {
                  if (trend == DOWN || trend == BREAKOUT_DOWN) {
                     // Trend reverse during an open trade, desire to close in Profit ASAP
                     minProfit = MathAbs(OrderCommission()) + MathAbs(OrderSwap());
                  }
               } else if (OrderComment() == "Open Breakout Buy Order") {
                  if (trend == DOWN || trend == BREAKOUT_DOWN) {
                     // Trend reverse during an open trade, desire to close in Profit ASAP
                     minProfit = MathAbs(OrderCommission()) + MathAbs(OrderSwap());
                  }
               } else if (OrderComment() == "Open Breakout Sell Order") {
                  if (trend == UP || trend == BREAKOUT_UP) {
                     // Trend reverse during an open trade, desire to close in Profit ASAP
                     minProfit = MathAbs(OrderCommission()) + MathAbs(OrderSwap());
                  }
               }

               if (OrderProfit() > minProfit) {
                  if (OrderType() == OP_BUY) {
                     if (OrderClose(OrderTicket(),OrderLots(),Bid,0) == true) {
                        // Permit new trades after open trades have been closed.
                        AllowNewTrades = true;
                     }
                  } else if (OrderType() == OP_SELL) {
                     if (OrderClose(OrderTicket(),OrderLots(),Ask,0) == true) {
                        // Permit new trades after open trades have been closed.
                        AllowNewTrades = true;
                     }
                  }
               } else {
                  datetime gmt = TimeGMT();
                  MqlDateTime GMT; 
                  TimeToStruct(gmt,GMT); 
                  int last_hour = GMT.hour-5; // NY Time adjustment
                  
                  // Friday = 5, 4 pm = 16
                  if (GMT.day_of_week == 5 && last_hour == 16) {
                     // If the day is Friday and in the last hour of 4 p.m.,
                     // close out all trades in a profit above costs ONLY
                     if (OrderProfit() > MathAbs(OrderCommission()+OrderSwap())) {
                        if (OrderType() == OP_BUY) {
                           if (OrderClose(OrderTicket(),OrderLots(),Bid,0) == true) {
                              // Don't permit new trades in the last hour on Friday after open trades have been closed.
                              AllowNewTrades = false;
                           }
                        } else if (OrderType() == OP_SELL) {
                           if (OrderClose(OrderTicket(),OrderLots(),Ask,0) == true) {
                              // Don't permit new trades in the last hour on Friday after open trades have been closed.
                              AllowNewTrades = false;
                           }
                        }
                     }
                  } else {
                     // Minimum not met, let's wait? Meanwhile, margin-protect library will monitoy
                     // the margin level and only close out trades forcibly if the margin level
                     // drops below safe levels - SEE BELOW
                  }
               }
            }
         }
      }
   }
   
   // Check MarginLevel when there are trades?
   static bool notified_margin_level_low = false;
   static bool notified_margin_level_safe = true;
   if (AccountMargin() > 0) {
      MarginLevel = CalculateMarginLevel();
      MarginLevelMin = CalculateMinMarginLevel();
      if (MarginLevel <= MarginLevelMin) {
         if (notified_margin_level_low == false) {
            Print("Margin Level is below minimum threshold of ",DoubleToString(MarginLevelMin));
            notified_margin_level_low = true;
            notified_margin_level_safe = false;
         }
         AllowNewTrades = false;
         double lots = LotsOptimize(Deposit, false);
         double minsltp=MarketInfo(Symbol(),MODE_SPREAD)+MarketInfo(Symbol(),MODE_STOPLEVEL)+PipProfit;
         RestoreSafeMarginLevel("Restoring Safe Margin Level",0,0,minsltp,lots);
      } else {
         if (notified_margin_level_safe == false) {
            Print("Margin Level back at SAFE levels");
            notified_margin_level_safe = true;
            notified_margin_level_low = false;
            AllowNewTrades = true;
         }
      }
   }
   
   // Auto Adjust MaxLossForceClose to be 10% of the AccountProfit, e.g. if AP=1.98, then MaxLossForceClose=-0.19
   double adjMaxLossForceClose = (MathAbs(AccountProfit()) / 10) * -1;
   if (adjMaxLossForceClose < MaxLossForceClose) {
      MaxLossForceClose = adjMaxLossForceClose;
      Print("Max loss to force close is adjusted to ",DoubleToString(adjMaxLossForceClose));
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
