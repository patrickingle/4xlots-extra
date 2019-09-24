//+------------------------------------------------------------------+
//|                                             marginprotectlib.mq4 |
//|        Copyright 2019, PressPage Entertainment Inc DBA RedeeCash |
//|                                               https://4xlots.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2019, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://4xlots.com"
#property version   "1.00"
#property strict

#include <margin-protect.mqh>

//+------------------------------------------------------------------+
//| CalculateMinMarginLevel                                          |
//+------------------------------------------------------------------+
double CalculateMinMarginLevel() export
{
   return (AccountBalance() + AccountLeverage());
}

//+------------------------------------------------------------------+
//| CalculateMarginLevel                                             |
//+------------------------------------------------------------------+
double CalculateMarginLevel() export
{
   double _MarginLevel = 0.0;
   
   if (AccountMargin() > 0) {
      _MarginLevel = (AccountEquity() / AccountMargin()) * 100;
   }
   
   return _MarginLevel;
}

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
//| CloseAnOpenOrder                                                 |
//+------------------------------------------------------------------+
void CloseAnOpenOrder(bool CloseNegativeOrder) export
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
//| CloseOpenOrders                                                  |
//+------------------------------------------------------------------+
void CloseOpenOrders(bool closeNegativeOrders=true,int multiplier=2) export
{
   int closed_positive_orders = 0;
 
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == true) {
         if( OrderSymbol() == Symbol() && OrderProfit() > (MathAbs(OrderCommission())*multiplier + MathAbs(OrderSwap())) ) {
            double close_price = Ask;
            if (OrderType() == OP_BUY) {
               close_price = Ask;
            } else if (OrderType() == OP_SELL) {
               close_price = Bid;
            }
            if (OrderClose(OrderTicket(),OrderLots(),close_price,0) == false) {
               Print(ErrorDescription(GetLastError()));
            } else {
               closed_positive_orders = 1;
               // close one order at time and recheck margin level on each tick
               return;
            }
         }
      }
   }
   
   if (closeNegativeOrders == true) {
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
//| RestoreSafeMarginLevel                                           |
//+------------------------------------------------------------------+
double RestoreSafeMarginLevel(string comment,int magic,double TP,double minsltp,double lots) export
{
   if (TradesSkewed() == true) {
      return CheckOpenHedgeTrade(comment,magic,TP,minsltp,lots);
   } else {
      CloseOpenOrders();
   }
   
   return (TP);
}

//+------------------------------------------------------------------+
//| TradesSkewed                                                     |
//+------------------------------------------------------------------+
bool TradesSkewed()
{
   double buy_lots = 0;
   double sell_lots = 0;

   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == true) {
         if( OrderSymbol() == Symbol()) {
            if (OrderType() == OP_BUY) {
               buy_lots = buy_lots + OrderLots();
            } else if (OrderType() == OP_SELL) {
               sell_lots = sell_lots + OrderLots();
            }
         }
      }
   }
   
   if (buy_lots == 0 && sell_lots > 0) {
      return true;
   } else if (sell_lots == 0 && buy_lots > 0) {
      return true;
   }
   
   return false;   
}
  
//+------------------------------------------------------------------+
//| CheckOpenHedgeTrade                                              |
//+------------------------------------------------------------------+
double CheckOpenHedgeTrade(string comment,int MagicNumber,double TP,double minSLTP,double lots) {
   double buy_lots = 0;
   double sell_lots = 0;
   int buy=0, sell=0;

   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) == true) {
         if( OrderSymbol() == Symbol()) {
            if (OrderType() == OP_BUY) {
               buy_lots = buy_lots + OrderLots();
            } else if (OrderType() == OP_SELL) {
               sell_lots = sell_lots + OrderLots();
            }
         }
      }
   }
   
   if (buy_lots == 0 && sell_lots > 0) {
      TP=Ask+((MathAbs(ProfitMoney(MagicNumber))/(TotalLots(MagicNumber)+lots))*Point)+minSLTP*Point;
      buy=OrderSend(Symbol(),OP_BUY,sell_lots/2,Ask,0,0,TP,comment,MagicNumber);
   } else if (sell_lots == 0 && buy_lots > 0) {
      TP=Bid-((MathAbs(ProfitMoney(MagicNumber))/(TotalLots(MagicNumber)+lots))*Point)-minSLTP*Point;
      sell=OrderSend(Symbol(),OP_SELL,buy_lots/2,Bid,0,0,TP,comment,MagicNumber);
   }
   
   return (TP);
}

//+------------------------------------------------------------------+
//| ProfitMoney                                                      |
//+------------------------------------------------------------------+
double ProfitMoney(int MagicNumber) export
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

//+------------------------------------------------------------------+
//| TotalLots                                                        |
//+------------------------------------------------------------------+
double TotalLots(int MagicNumber) export
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

//+------------------------------------------------------------------+
//| LastType                                                         |
//+------------------------------------------------------------------+
string LastType(int MagicNumber) export
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

//+------------------------------------------------------------------+
//| LastPrice                                                        |
//+------------------------------------------------------------------+
double LastPrice(int tip,int MagicNumber) export
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

//+------------------------------------------------------------------+
//| ModifyTP                                                         |
//+------------------------------------------------------------------+
void ModifyTP(int tip,double tp,int MagicNumber) export
{
   int move=0;
   
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

//+------------------------------------------------------------------+
//| TotalOrders                                                      |
//+------------------------------------------------------------------+
int TotalOrders(int MagicNumber) export
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
  
  
//+------------------------------------------------------------------+
