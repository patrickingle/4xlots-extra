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
extern int MaxTradesPerCurrencyPair = 1; // number of trades permitted per currency pair
extern double TradeProfit = 0.5; // Profit per trade over costs
extern bool MarginProtect = false;
extern bool EnableSL = true;
extern double RiskPercent = 0.5; // 0.5%
extern int WaitBeforeNextTrade = 5000;
extern bool PermitAdditionalTrades = true;

double PipProfit   = 10.0;
double MarginLevel = 0.0;
bool momentum_high = false;

//+------------------------------------------------------------------+
//| INSTRUCTIONS:
//| ------------
//| When switching between Accounts, turn off the Expert before switching
//| otherwise, you could inadvertently open multiple trades on the
//| new account.
//|
//| This Expert Advisor is designed to permit a single open trade at a time
//| allowing to be attached to multiple currency pairs.
//|
//| Ideally, the target is earn at least $1 per day, but if your trades
//| are taking longer to close, you may want to reduce the DailyTargetProfit
//| amount.
//|
//| If you want to turn trading on selected currency pairs without
//| removing the Expert Advsior, just set the AllowNewTrades to FALSE.
//| This does not stop closing out the open trades or the margin protect
//| algorithm from functioning.
//|
//| Currency Pairs Tested: EURUSD, USDJPY, EURGPY, GBPJPY, USDCAD
//| With $100 deposit, use a maximum of 5 currency pairs 
//|
//| Indicators Required:
//| -------------------
//| Using the M1 chart,
//| Bands
//| Price Channel
//| Pivot Points v4
//|
//|
//| Currency Pairs -CAUTION
//| -----------------------
//| The following currency pairs should be traded with caution, because
//| during testing they produced large swings and a large negative 
//| balance.
//|
//| USDJPY, EURJPY
//|
//| Currency Pairs - RECOMMENDED
//| ----------------------------
//| The following currency pairs appeared safe trading during testing.
//|
//| EURUSD, GBPJPY, USDCAD, AUDCAD
//+------------------------------------------------------------------+


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
   double profit = TradeProfit;

   // Check Momentum, if >100 OR <99.95, then stop NEW trades
   double momentum = iMomentum(Symbol(),0,100,PRICE_CLOSE,0);
   if (momentum > 100) {
      AllowNewTrades = false;
      if (momentum_high == false) {
         Comment("Momentum is high, new trades suspended");
         momentum_high = true;
      }
   } else {
      momentum_high = false;
   }
   

   if (TotalOrders(0) < MaxTradesPerCurrencyPair && AllowNewTrades == true) {
      trend = TrendDirection();
      
      double lots = LotsOptimize(Deposit, false);
      //Print("Lots=",lots);
      if (lots == 0.0) {
         lots = MarketInfo(Symbol(),MODE_MINLOT);
      }
      double tp = 0.0;
      int ticket = 0;
      
      Comment("Trend: ",TrendDescription(trend));
   
      switch (trend) {
         case DOWN:
            ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,0,0.0,0.0,"Open Sell Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()-(TP * 100 * Point),Digits),0) == true) {
                     Sleep(WaitBeforeNextTrade);
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
                     Sleep(WaitBeforeNextTrade);
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
                     Sleep(WaitBeforeNextTrade);
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
                     Sleep(WaitBeforeNextTrade);
                  }
               }
               // Don't permit new trades once there is an open trade
               AllowNewTrades = false;
            }
            break;
         case COUNTER_UP:
            ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,0,0.0,0.0,"Open Counter Buy Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()+(TP * 100 * Point),Digits),0) == true) {
                     Sleep(WaitBeforeNextTrade);
                  }
               }
               // Don't permit new trades once there is an open trade
               AllowNewTrades = false;
            }
            break;
         case COUNTER_DOWN:
            ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,0,0.0,0.0,"Open Counter Sell Order");
            if (ticket != -1) {
               if (OrderSelect(ticket,SELECT_BY_TICKET) == true) {
                  // Take Profit is the dollar value of $1 over cost, the TP * 100 * Point formats to the currency price
                  double TP = profit + MathAbs(OrderCommission())+MathAbs(OrderSwap());
                  if (OrderModify(ticket,OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(OrderOpenPrice()-(TP * 100 * Point),Digits),0) == true) {
                     Sleep(WaitBeforeNextTrade);
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
               //Print("MinProfit: ",minProfit,", Current Profit: ",OrderProfit());
               if (OrderComment() == "Open Sell Order" || OrderComment() == "Open Breakout Sell Order" || OrderComment() == "Open Counter Sell Order") {
                  if (trend == UP || trend == BREAKOUT_UP || trend == COUNTER_UP) {
                     if (OrderStopLoss() == 0.0) {
                        double SL = OrderStopLoss();
                        if (OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(High[0]+(SL * 100 * Point),Digits),OrderTakeProfit(),0) == true) {
                        }
                     } else {
                        // Trend is same direction as Trade, then remove the Stop Loos
                        if (OrderModify(OrderTicket(),OrderOpenPrice(),0.0,OrderTakeProfit(),0) == true) {
                        }
                     }
                     // Trend reverse during an open trade, desire to close in Profit ASAP
                     minProfit = MathAbs(OrderCommission()) + MathAbs(OrderSwap());
                  }
               } else if (OrderComment() == "Open Buy Order" || OrderComment() == "Open Breakout Buy Order" || OrderComment() == "Open Counter Buy Order") {
                  if (trend == DOWN || trend == BREAKOUT_DOWN || trend == COUNTER_DOWN) {
                     if (OrderStopLoss() == 0.0) {
                        double SL = AccountEquity() * (RiskPercent / 100);
                        if (OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Low[0]-(SL * 100 * Point),Digits),OrderTakeProfit(),0) == true) {
                        }
                     } else {
                        // Trend is same direction as Trade, then remove the Stop Loos
                        if (OrderModify(OrderTicket(),OrderOpenPrice(),0.0,OrderTakeProfit(),0) == true) {
                        }
                     }
                     // Trend reverse during an open trade, desire to close in Profit ASAP
                     minProfit = MathAbs(OrderCommission()) + MathAbs(OrderSwap());
                  }
               }
               //Print("Updated MinProfit: ",minProfit,", Current Profit: ",OrderProfit());
               if (OrderProfit() > minProfit) {
                  if (OrderType() == OP_BUY) {
                     if (OrderClose(OrderTicket(),OrderLots(),Bid,0) == true) {
                        // Permit new trades after open trades have been closed.
                        AllowNewTrades = !momentum_high;
                     }
                  } else if (OrderType() == OP_SELL) {
                     if (OrderClose(OrderTicket(),OrderLots(),Ask,0) == true) {
                        // Permit new trades after open trades have been closed.
                        AllowNewTrades = !momentum_high;
                     }
                  }
               } else {
                  // OrderProfit has not reach minProfit.
                  datetime gmt = TimeGMT();
                  MqlDateTime GMT; 
                  TimeToStruct(gmt,GMT); 
                  int last_hour = GMT.hour-5; // NY Time adjustment
                  
                  // Friday = 5, 4 pm = 16
                  if (GMT.day_of_week == 5 && last_hour == 16) {
                     // If the day is Friday and in the last hour of 4 p.m.,
                     // close out all trades in a profit above costs ONLY
                     if (OrderProfit() > (MathAbs(OrderCommission())+MathAbs(OrderSwap()))) {
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
                     
                     // Check of OrderProfit > $2, then increase MaxOrders by OrderProfit/2
                     // Each time the OrderProfit descrease by a factor of $2, the max trades per currency is increased by one.
                     // automatically adjusted when profit raises back up and resets to 1 when profit is greater than -$2.
                     double ccyProfit = ProfitMoney(0);
                     //Print("CCY Profit: ", MathAbs((int)ccyProfit/2));
                     // TODO: needs to be scalable, when the balance/equity/lots are large, an instant open trade
                     //       can trigger this action to open more trades and dangeriously risking the account
                     //       for a margin call. e.g. a 1 lot trade at opening could produce a -$10 profit,
                     //       hence invoking this action to open 3 more trades of equal quantity.
                     //       Currently safe as long as lot size stay at 0.01 but 4xlots will automatically increase the
                     //       lots as the equity increases to the MAX LOTS per account.
                     if (ccyProfit < -4.00 && PermitAdditionalTrades == true) {
                        MaxTradesPerCurrencyPair = (int)MathAbs((int)ccyProfit/2);
                        //Print("Max Trades changed: ", MaxTradesPerCurrencyPair);
                     } else if (ccyProfit < -2.00 && PermitAdditionalTrades == true) {
                        MaxTradesPerCurrencyPair = 2;
                     } else {
                        MaxTradesPerCurrencyPair = 1;
                     }
                     AllowNewTrades = !momentum_high;
                  }
               }
            }
         }
      }
   }
   
   
   // Check MarginLevel when there are trades?
   static bool notified_margin_level_low = false;
   static bool notified_margin_level_safe = true;
   if (AccountMargin() > 0 && MarginProtect == true) {
      MarginLevel = CalculateMarginLevel();
      MarginLevelMin = CalculateMinMarginLevel();
      if (MarginLevel <= MarginLevelMin) {
         if (notified_margin_level_low == false) {
            Print("Margin Level is below minimum threshold of ",DoubleToString(MarginLevelMin));
            notified_margin_level_low = true;
            notified_margin_level_safe = false;
         }
         AllowNewTrades = false;
         PipProfit = NormalizeDouble(TradeProfit * 100, Digits);
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
      //Print("Max loss to force close is adjusted to ",DoubleToString(adjMaxLossForceClose));
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
