//+------------------------------------------------------------------+
//|                                                         1BUY.mq4 |
//|                                  Copyright 2017, PHK Corporation |
//|                                           https://www.4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, PHK Corporation"
#property link      "https://www.4xlots.com"
#property version   "1.00"
#property strict

string MeIs                =    "" ;

extern double Lots                =       1.0 ;
extern double ProfitMade          =       2   ; 
extern double LossLimit           =       0   ;
extern double BreakEven           =       0   ;
extern int    Slippage            =       0   ;
extern int PipProfit = 10;
extern bool AllowNewTrades = true;

// Trade control
int            MagicNumber;
double         LL2SL=25;
double         myPoint;                              // support for 3/5 decimal places
double         MarginLevel;
double         minsltp;

// Bar handling
datetime      bartime=0;                            // used to determine when a bar has moved

// used for verbose error logging
#include <4xlots.mqh>
#include <margin-protect.mqh>
#include <trend.mqh>
#include <trailingstop.mqh>

string strTrend;
static Trend trend=UNKNOWN; // 0=down, 1=up, 2=reversal/unknown/limbo

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // get normalized Point based on Broker decimal places
   myPoint = SetPoint();

   trend = TrendDirection();

   switch(trend) {
      case UP:
         MeIs="1BUY";
         break;
      case DOWN:
         MeIs="1SELL";
         break;
      case UNKNOWN:
         MeIs="";
         break;
      case BREAKOUT_DOWN:
         MeIs="1BUY";
         break;
      case BREAKOUT_UP:
         MeIs="1SELL";
         break;
   }
   if(MeIs=="1SELL")
     {
      MagicNumber=142555;
      OpenSell();
     }
      
   if(MeIs=="1BUY")
     {
      MagicNumber=142222;
      OpenBuy();
     }
   
   Print("Init Complete "+MeIs);
   Comment(" ");
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("DE-Init Complete "+MeIs);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int cnt;

   double CurrentProfit=0;
   int    OrdersPerSymbol;
      
   double SL;
   double TP;
   
   int gle;  // GetLastError
   

   //
   // Order Management
   //

   for(cnt=OrdersTotal();cnt>=0;cnt--) {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == true) {
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber) {
            if(OrderType()==OP_BUY) {
               CurrentProfit=(Bid-OrderOpenPrice()) ;

               //
               // Modify for break even
               //=======================
               //
               // OrderStopLoss will be equal to OrderOpenPrice if this event happens
               // thus it will only ever get executed one time per ticket
               if( BreakEven>0 ) {
                  if (CurrentProfit >= BreakEven*myPoint && OrderOpenPrice()>OrderStopLoss()) {
                     SL=0; //OrderOpenPrice()+(Ask-Bid);
                     TP=OrderTakeProfit();
                     if (OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, White) == true) {
                        gle=GetLastError();
                        if(gle==0) {
                           Print("MODIFY BUY BE Ticket="+DoubleToString(OrderTicket())+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP));
                        } else {
                           Print("-----ERROR----- MODIFY BUY  BE Bid="+DoubleToString(Bid)+" error="+IntegerToString(gle)+" "+ErrorDescription(gle));
                        }
                     }
                  }
               }

               //
               // check for trailing stop
               //=========================
               //
               // This starts trailing after 'TrailStop' pips of profit
               TrailingStop();


               // Did we make a profit
               //======================
               if(ProfitMade>0 && CurrentProfit>=(ProfitMade*myPoint)) {
                  CloseBuy("PROFIT");
               }
                 
   
               // Did we take a loss
               //====================
               if(LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*myPoint)) {
                  CloseBuy("LOSS");
               }
           } // if BUY


            if(OrderType()==OP_SELL) {
               // add up pips
               // CurrentProfit=(Close[0]-OrderOpenPrice()) * (-1) ;
               // add up dollars
               // CurrentProfit=OrderProfit();
   
               CurrentProfit=(OrderOpenPrice()-Ask);
   
               //
               // Modify for break even
               //=======================
               //
               // OrderStopLoss will be equal to OrderOpenPrice if this event happens
               // thus it will only ever get executed one time per ticket
               if( BreakEven>0 ) {
                  if (CurrentProfit >= BreakEven*myPoint && OrderOpenPrice()<OrderStopLoss()) {
                     SL=0; //OrderOpenPrice()-(Ask-Bid);
                     TP=OrderTakeProfit();
                     if (OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, Red) == true) {
                        gle=GetLastError();
                        if(gle==0) {   
                           Print("MODIFY SELL BE Ticket="+DoubleToString(OrderTicket())+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP));
                        } else {
                           Print("-----ERROR----- MODIFY SELL BE Ask="+DoubleToString(Ask)+" error="+IntegerToString(gle)+" "+ErrorDescription(gle));
                        }
                     }
                  }
               }

               //
               // check for trailing stop
               //=========================
               //
               // This starts trailing after 'TrailStop' pips of profit
               TrailingStop();
   
               // Did we make a profit
               //======================
               if( ProfitMade>0 && CurrentProfit>=(ProfitMade*myPoint) ) {
                  CloseSell("PROFIT");
               }
             
               // Did we take a loss
               //====================
               if( LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*myPoint) ) {
                  CloseSell("LOSS");
               }

            } //if SELL
         } // if(OrderSymbol)
      } // if (OrderSelect)
   } // for

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
         TP = OrderTakeProfit();
         TP = RestoreSafeMarginLevel(__FILE__+"-"+IntegerToString(__LINE__),MagicNumber,TP,minsltp,Lots);
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

   // get out of script once order count reaches zero

   Sleep(500);   
   RefreshRates();
   
   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == true) {
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber) {
            OrdersPerSymbol++;
         }
      }
     }

   if(OrdersPerSymbol==0 && AllowNewTrades == true) {
      trend = TrendDirection();
   
      switch(trend) {
         case UP:
            MeIs="1BUY";
            break;
         case DOWN:
            MeIs="1SELL";
            break;
         case UNKNOWN:
            MeIs="";
            break;
         case BREAKOUT_DOWN:
            MeIs="1BUY";
            break;
         case BREAKOUT_UP:
            MeIs="1SELL";
            break;
      }
   
      if(MeIs=="1SELL")
        {
         MagicNumber=142555;
         OpenSell();
        }
         
      if(MeIs=="1BUY")
        {
         MagicNumber=142222;
         OpenBuy();
        }
   }

   Print(MeIs+" Open Orders="+IntegerToString(OrdersPerSymbol)+"    CurrentProfit="+DoubleToString(CurrentProfit)+" ProfitMade="+DoubleToString(ProfitMade*myPoint) );

  //} //unindented while
   
  }
  

//ENTRY LONG (buy, Ask) 
void OpenBuy()
{
   int      gle=0;
   int      ticket=0;
   
   double SL=0;
   double TP=0;
   //int loopcount;
   
   Lots = LotsOptimize(Deposit,Preserve); // LotsOptimize(1000,AccountEquity(),AccountLeverage(),MarketInfo(Symbol(),MODE_MAXLOT));
   if (Lots == 0) {
      Lots = MarketInfo(Symbol(),MODE_MINLOT);
   }
   
   // PLACE order is independent of MODIFY order. 
   // This is mandatory for ECNs and acceptable for retail brokers
   
   ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,MeIs,MagicNumber,White);
   gle=GetLastError();
   
   if (gle==0) {
      Print("BUY PLACED Ticket="+IntegerToString(ticket)+" Ask="+DoubleToString(Ask)+" Lots="+DoubleToString(Lots));
   } else {
      Print("-----ERROR-----  Placing BUY order: Lots="+DoubleToString(Lots)+" Bid="+DoubleToString(Bid)+" Ask="+DoubleToString(Ask)+" ticket="+IntegerToString(ticket)+" Err="+IntegerToString(gle)+" "+ErrorDescription(gle)); 
      
      RefreshRates();
      Sleep(500);
   }
   
   
   // don't set TP and SL both to zero, they're already there
   if(LossLimit==0 && ProfitMade==0) return;
   
   if(LossLimit  ==0) SL=0;
   if(ProfitMade ==0) TP=0;
   if(LossLimit   >0) SL=Ask-((LossLimit+LL2SL)*myPoint );
   if(ProfitMade  >0) TP=Ask+((ProfitMade+LL2SL)*myPoint );
   
   if (OrderModify(ticket,OrderOpenPrice(),SL,TP,0,White) == true) {
      gle=GetLastError();
      
      if (gle==0) {
         Print("BUY MODIFIED Ticket="+IntegerToString(ticket)+" Ask="+DoubleToString(Ask)+" Lots="+DoubleToString(Lots)+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP));
      } else {
         Print("-----ERROR-----  Modifying BUY order: Lots="+DoubleToString(Lots)+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP)+" Bid="+DoubleToString(Bid)+" Ask="+DoubleToString(Ask)+" ticket="+IntegerToString(ticket)+" Err="+IntegerToString(gle)+" "+ErrorDescription(gle)); 
         
         RefreshRates();
         Sleep(500);
      }
   }
}//BUYme



   //ENTRY SHORT (sell, Bid)
void OpenSell()
{
   int      gle=0;
   int      ticket=0;
   
   double SL=0;
   double TP=0;
   //int loopcount;
   Lots = LotsOptimize(Deposit,Preserve);
   if (Lots == 0) {
      Lots = MarketInfo(Symbol(),MODE_MINLOT);
   }

   // PLACE order is independent of MODIFY order. 
   // This is mandatory for ECNs and acceptable for retail brokers

   ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,MeIs,MagicNumber,Red);
   gle=GetLastError();
   if(gle==0) {
      Print("SELL PLACED Ticket="+IntegerToString(ticket)+" Bid="+DoubleToString(Bid)+" Lots="+DoubleToString(Lots));
   } else {
      Print("-----ERROR-----  placing SELL order: Lots="+DoubleToString(Lots)+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP)+" Bid="+DoubleToString(Bid)+" Ask="+DoubleToString(Ask)+" ticket="+IntegerToString(ticket)+" Err="+IntegerToString(gle)+" "+ErrorDescription(gle)); 
                      
      RefreshRates();
      Sleep(500);
   }

   
   // don't set TP and SL both to zero, they're already there
   if(LossLimit==0 && ProfitMade==0) return;
   
   if(LossLimit  ==0) SL=0;
   if(ProfitMade ==0) TP=0;
   if(LossLimit   >0) SL=Bid+((LossLimit+LL2SL)*myPoint );
   if(ProfitMade  >0) TP=Bid-((ProfitMade+LL2SL)*myPoint );
   
   if (OrderModify(ticket,OrderOpenPrice(),SL,TP,0,Red) == true) {
      gle=GetLastError();
      if(gle==0) {
         Print("SELL MODIFIED Ticket="+IntegerToString(ticket)+" Bid="+DoubleToString(Bid)+" Lots="+DoubleToString(Lots)+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP));
      } else {
         Print("-----ERROR-----  modifying SELL order: Lots="+DoubleToString(Lots)+" SL="+DoubleToString(SL)+" TP="+DoubleToString(TP)+" Bid="+DoubleToString(Bid)+" Ask="+DoubleToString(Ask)+" ticket="+IntegerToString(ticket)+" Err="+IntegerToString(gle)+" "+ErrorDescription(gle)); 
                         
         RefreshRates();
         Sleep(500);
      }
   }
}//SELLme


void CloseBuy (string myInfo)
{
   int gle;
   
   string bTK=" Ticket="+IntegerToString(OrderTicket());
   string bSL=" SL="+DoubleToString(OrderStopLoss());
   string bTP=" TP="+DoubleToString(OrderTakeProfit());
   string bPM;
   string bLL;
   string bER;

   bPM=" PM="+DoubleToString(ProfitMade);
   bLL=" LL="+DoubleToString(LossLimit);

   if (OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White) == true) {
      gle=GetLastError();
      bER=" error="+IntegerToString(gle)+" "+ErrorDescription(gle);

      if (gle==0) {
         Print("CLOSE BUY "+myInfo+ bTK + bSL + bTP + bPM + bLL);
      } else {
         Print("-----ERROR----- CLOSE BUY "+myInfo+ bER +" Bid="+DoubleToString(Bid)+ bTK + bSL + bTP + bPM + bLL);
         RefreshRates();
         Sleep(500);
      }
   }
}


void CloseSell (string myInfo)
{
   int gle;

   string sTK=" Ticket="+IntegerToString(OrderTicket());
   string sSL=" SL="+DoubleToString(OrderStopLoss());
   string sTP=" TP="+DoubleToString(OrderTakeProfit());
   string sPM;
   string sLL;
   string sER;
      
   sPM=" PM="+DoubleToString(ProfitMade);
   sLL=" LL="+DoubleToString(LossLimit);

   if (OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red)==true){
      gle=GetLastError();
      sER=" error="+IntegerToString(gle)+" "+ErrorDescription(gle);
      
      if (gle==0) {
         Print("CLOSE SELL "+myInfo + sTK + sSL + sTP + sPM + sLL);
         //break;
      } else {
         Print("-----ERROR----- CLOSE SELL "+myInfo+ sER +" Ask="+DoubleToString(Ask)+ sTK + sSL + sTP + sPM + sLL);
         RefreshRates();
         Sleep(500);
      }
   }
}      


// Function to correct the value of Point
// for brokers that add an extra digit to price
// Courtesy of Robert Hill

double SetPoint()
{
   double mPoint;
  
   if (Digits < 4)
      mPoint = 0.01;
   else
      mPoint = 0.0001;
  
   return(mPoint);
}


//+------------------------------------------------------------------+
