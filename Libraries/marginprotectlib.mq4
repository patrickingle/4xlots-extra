//+------------------------------------------------------------------+
//|                                               margin-protect.mq4 |
//|                                  Copyright 2017, PHK Corporation |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://4xlots.com"
#property version   "1.00"
#property strict

#include <margin-protect.mqh>

//+------------------------------------------------------------------+
//| IsMarginLevelLessThan                                            |
//+------------------------------------------------------------------+
bool IsMarginLevelLessThan(double MarginLevelTest) export
{
   double _MarginLevel = 0.0;
    
   if (AccountMargin() > 0) {
      _MarginLevel = (AccountEquity() / AccountMargin()) * 100;
      return (_MarginLevel < MarginLevelTest);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| CloseOpenOrders                                                  |
//+------------------------------------------------------------------+
void CloseAnOpenOrder(bool CloseNegativeOrder,double MaxLossForceClose) export
{
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == true) {
         if( OrderSymbol() == Symbol() && OrderProfit() > (MathAbs(OrderCommission()) + MathAbs(OrderSwap())) ) {
            double close_price = Ask;
            if (OrderType() == OP_BUY) {
               close_price = Ask;
            } else if (OrderType() == OP_SELL) {
               close_price = Bid;
            }
            if (OrderClose(OrderTicket(),OrderLots(),close_price,0) == false) {
               Print(ErrorDescription(GetLastError()));
            } else {
               // close one order at time and recheck margin level on each tick
               return;
            }
         }
      }
   }
   
   if (CloseNegativeOrder == true) {
      for( int i = 0 ; i < OrdersTotal() ; i++ ) {
         if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == true) {
            if( OrderSymbol() == Symbol() && OrderProfit() > MaxLossForceClose) {
               double close_price = Ask;
               if (OrderType() == OP_BUY) {
                  close_price = Ask;
               } else if (OrderType() == OP_SELL) {
                  close_price = Bid;
               }
               if (OrderClose(OrderTicket(),OrderLots(),close_price,0) == false) {
                  Print(ErrorDescription(GetLastError()));
               } else {
                  // close one order at time and recheck margin level on each tick
                  return;
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//+ Break Even                                                       |
//+------------------------------------------------------------------+
bool BreakEven(int MagicNumber) export
{
   int Ticket=0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true) {
         if (MagicNumber == 0) {
            if(OrderSymbol() == Symbol()){
               Ticket = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, Green);
               if(Ticket < 0) {
                  Print(ErrorDescription(GetLastError()));
               }
               break;
            }
         } else {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber){
               Ticket = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, Green);
               if(Ticket < 0) {
                  Print(ErrorDescription(GetLastError()));
               }
               break;
            }
         }
      }
   }
   
   return(Ticket);
}
//+------------------------------------------------------------------+
