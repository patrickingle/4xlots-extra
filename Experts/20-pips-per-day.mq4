//+------------------------------------------------------------------+
//|                                              20-pips-per-day.mq4 |
//|   Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash |
//|                                           https://www.4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://www.4xlots.com"
#property version   "1.00"
#property strict

#include <4xlots.mqh>
#include <margin-protect.mqh>
#include <trend.mqh>
#include <trailingstop.mqh>
#include <stderror.mqh>
#include <stdlib.mqh>

extern string StartOpenOrdersOn = "FROM 00:00 UNTIL 01:00"; // look on your chart to see when your daily bar open
extern bool UseStopLoss = false;
extern bool IPreferStopOrders = true;
extern int DistanceFromOpen = 20; // Distance the Limit Orders Should be placed
extern double TakeProfit = 40;
extern double StopLoss = 20;
extern double StopAndReverseOnLossOf = 100;
extern int MinimumToContinue = 100; // pips the daily bar must have
extern double LotSize = 0.1;
extern int Slippage = 15;
extern string BuyComment = "20 pips per day BUY";
extern string SellComment = "20 pips per day SELL";
extern color clOpenBuy = Blue;
extern color clOpenSell = Red;
extern int MagicNumber = 123456789;
extern int PipProfit = 10;
extern bool AllowNewTrades = true;

static int LASTRUN_v1_1; // verifica se uma nova bar for aberta
int ticket_buy_20PPD = 0, ticket_sell_20PPD = 0;
double MarginLevel,TP;
double minsltp;


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
void OnTick()
  {
//---
   int total_orders = OrdersTotal();

   int minute = TimeMinute(TimeCurrent());
   int hour   = TimeHour(TimeCurrent());
   //"FROM 02:14 UNTIL 03:15"
   string temp_variable = ""; // variable used for conversions
   temp_variable = StringSubstr(StartOpenOrdersOn,5,6);
   int start_allowed_time_hour   = StrToInteger(temp_variable);
   
   temp_variable = StringSubstr(StartOpenOrdersOn,8,9);
   int start_allowed_time_minute = StrToInteger(temp_variable);
   
   temp_variable = StringSubstr(StartOpenOrdersOn,17,18);
   int end_allowed_time_hour     = StrToInteger(temp_variable);
   
   temp_variable = StringSubstr(StartOpenOrdersOn,20,21);
   int end_allowed_time_minute   = StrToInteger(temp_variable);
   if (hour >= start_allowed_time_hour && 
       //minute >= start_allowed_time_minute &&
       hour <= end_allowed_time_hour
       // && minute <= end_allowed_time_minute
   ) {
      Comment("EA Start 20-pips-per-day:", TimeDay(TimeCurrent()),"/",TimeMonth(TimeCurrent()),"/",TimeYear(TimeCurrent()));
   } else {
      Comment("EA will trade only on this time: ", StartOpenOrdersOn);
      return;
   }
   minsltp=MarketInfo(Symbol(),MODE_SPREAD)+MarketInfo(Symbol(),MODE_STOPLEVEL)+PipProfit;
   
   ticket_buy_20PPD = 0;
   ticket_sell_20PPD = 0;
   
   double curr_open = iOpen(NULL, 0, 0);
   double last_high = iHigh(NULL, 0, 1);
   double last_low = iLow(NULL, 0, 1);
   double last_close = iClose(NULL, 0, 1);
   
   double is_able_to_continue = (last_high - last_low)*MathPow(10,Digits);

   Comment("is_able_to_continue: ", is_able_to_continue);
   if (is_able_to_continue < MinimumToContinue) {
      Comment("EA is not able to continue previous bar moved less than ", MinimumToContinue, " pips");
      return;
   } else {
      Comment("EA is able to continue :). Good trade.");
   }
   double buy_stoploss,sell_stoploss, buy_price, sell_price, buy_take_profit, sell_take_profit;
   int order_buy_type,order_sell_type;
   
   // now we choose depending on what people want
   if (IPreferStopOrders) {
         buy_price        = curr_open+DistanceFromOpen*Point;
         sell_price       = curr_open-DistanceFromOpen*Point;
         order_buy_type   = OP_BUYSTOP;
         order_sell_type  = OP_SELLSTOP;
   } else {
         buy_price        = Ask;
         sell_price       = Bid;
         order_buy_type   = OP_BUY;
         order_sell_type  = OP_SELL;
   }
   if (UseStopLoss) {
      buy_stoploss     = buy_price-(StopLoss*Point);
      sell_stoploss    = sell_price+(StopLoss*Point);
   } else {
      buy_stoploss = 0;
      sell_stoploss = 0;
   }
   buy_take_profit  = buy_price+(TakeProfit*Point);
   sell_take_profit = sell_price-(TakeProfit*Point);
   
   LotSize = LotsOptimize(Deposit,Preserve);
   
   if (OrderSelect(ticket_buy_20PPD, SELECT_BY_TICKET, MODE_TRADES) == false && AllowNewTrades == true) {
      ticket_buy_20PPD = OrderSend(Symbol(),order_buy_type,LotSize,buy_price,Slippage,buy_stoploss,buy_take_profit,BuyComment,MagicNumber,0,clOpenBuy);
      if (ticket_buy_20PPD < 0) {
         Print("Open BUY order error: ", ErrorDescription(GetLastError()));
      }
   }
   
   if (OrderSelect(ticket_sell_20PPD, SELECT_BY_TICKET, MODE_TRADES) == false && AllowNewTrades == true) {
      ticket_sell_20PPD = OrderSend(Symbol(),order_sell_type,LotSize,sell_price,Slippage,sell_stoploss,sell_take_profit,SellComment,MagicNumber,0,clOpenSell); 
      if (ticket_sell_20PPD < 0) {
         Print("Open SELL order error: ", ErrorDescription(GetLastError()));
      }
   }
   
   // Invoke the TrailingStop function in the trailingstop library to auto adjust the stoploss
   TrailingStop();

   // Check MarginLevel when there are trades?
   static bool notified_margin_level_low = false;
   static bool notified_margin_level_safe = false;
   if (AccountMargin() > 0) {
      MarginLevel = CalculateMarginLevel();
      if (MarginLevel <= MarginLevelMin) {
         if (notified_margin_level_low == false) {
            Print("Margin Level is below minimum threshold of ",DoubleToString(MarginLevelMin));
            notified_margin_level_low = true;
            notified_margin_level_safe = false;
         }
         AllowNewTrades = false;
         TP = RestoreSafeMarginLevel(__FILE__+"-"+IntegerToString(__LINE__),MagicNumber,TP,minsltp,LotSize);
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
      Print("Max loss to force close is adjusted to ",DoubleToString(adjMaxLossForceClose));
   }
   
  }
//+------------------------------------------------------------------+
