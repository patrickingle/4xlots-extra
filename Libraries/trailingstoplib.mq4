//+------------------------------------------------------------------+
//|                                              trailingstoplib.mq4 |
//|        Copyright 2019, PressPage Entertainment Inc DBA RedeeCash |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2019, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://4xlots.com"
#property version   "1.01"
#property strict

#include <trailingstop.mqh>

//+------------------------------------------------------------------+
//| TrailingStop                                                     |
//+------------------------------------------------------------------+
void TrailingStop() export
{
   int tic=0;
   double StopLoss=0.0;
   
   if(OrdersTotal()>0)
   {
      for(int i=0;i<OrdersTotal();i++)
      {
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true) {
            if (OrderSymbol() == Symbol()) {
               if(TrailingPoints<MarketInfo(OrderSymbol(),MODE_STOPLEVEL) && TrailingPoints>0) {
                  TrailingPoints=MarketInfo(OrderSymbol(),MODE_STOPLEVEL);  
                  Print(OrderSymbol()+": You entered a lower trailing stop level than allowed. It will be changed to the minimum allowed level");
               }
               
               if(OrderType()==OP_BUY) {
                  if(MarketInfo(OrderSymbol(),MODE_BID)-OrderOpenPrice()>=TrailingPoints*Point) {
                     StopLoss = MarketInfo(OrderSymbol(),MODE_BID)-(TrailingPoints*Point);
                     if(StopLoss>OrderStopLoss()) {
                        tic=OrderModify(OrderTicket(),OrderOpenPrice(),StopLoss,OrderTakeProfit(),0,CLR_NONE);
                     }
                  }
               }
               if(OrderType()==OP_SELL) {
                  if(OrderOpenPrice()-MarketInfo(OrderSymbol(),MODE_ASK)>=TrailingPoints*Point) {
                     StopLoss = MarketInfo(OrderSymbol(),MODE_ASK)+(TrailingPoints*Point);
                     if(StopLoss<OrderStopLoss()) {
                        tic=OrderModify(OrderTicket(),OrderOpenPrice(),StopLoss,OrderTakeProfit(),0,CLR_NONE);
                     }
                  }
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
