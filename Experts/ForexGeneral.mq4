//+------------------------------------------------------------------+
//|                                                 ForexGeneral.mq4 |
//|                                    Copyright 2018, RedeeCash LTD |
//|                                        https://forexgeneral.info |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, RedeeCash LTD"
#property link      "https://forexgeneral.info"
#property version   "1.00"
#property strict

#include <ForexGeneral.mqh>


//
// External - User variables
//
//extern bool    Debug    = false;
extern bool    TradeEnabled       = true;
extern double  MinEquity          = 0;
extern double  MinimumProfit      = 2;
extern bool    MoneyManagement    = false;
extern double  Risk               = 2.5;
extern bool    Hedge              = false;
// Increases the trend side lots by this multple for a hedge trade
extern double  HedgeMultiple      = 2;       
// 0=low [<0.63%],1=medium[<0.77%],2=high
extern int     HedgeRisk          = 0;       
// One trade open at a time per currency
extern bool    OTS                = false;   
// One trade open at a time for all currencies/charts
extern bool    OTG                = false;   
// The maximum lots   
extern double  MaxLots            = 1000;    
// value is in seconds (660=10 mins; 172800=48 hrs[2 days]
extern datetime   Expiry             = 172800;  
extern int  slippage           = 10;
extern double  TrailingStop       = 50;
//extern bool    AdjustStops        = true;
extern string  name               = "4XITE";
// turns on voice confirmation after each trade
extern bool    voice_confirmation = false;     
extern string  Currency1          = "AUDJPYFXF";
extern string  Currency2          = "CADJPYFXF";
extern string  Currency3          = "AUDCADFXF";

//
// Internal variables
//
int      mId, mCmd;
string   mSymbol;
double   mLots, mPrice;
int      mSlippage;
string   mComment;
int      mColor;
string   mTimestamp;
int      mCompleted, mHandle, mMagic;
string   mExpiration;
double   mStoploss, mTakeprofit;
double   mVolume;
string   msg;
double   Leverage;
double   StopLevel;
int      MagicNumber;
string   MagicName;

// default to a (-1) as the DLL-API does no operation if this value is passed by mistake.
int session=-1; 

string   GlobalNamePrefix = "4xite_";
string   GlobalNameRandomNumber;

bool     close_all = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);

   Print(GetVersion());

   if (AccountEquity() < MinEquity) {
      Print("Trading is disabled for account balances less than $1000");
      Alert("Trading is disabled. See journal");
      StopScript();
      return(-1);
   }

   if (name == "") {
      Print("Your Name Must be provided to activate Forex Raptor Freeware");
      Alert("You must provide your name");
      StopScript();
      return(-1);
   }
   
   if (Expiry < 660) {
      Print("Expiration cannot be set less than 660 seconds (must be > 11 minutes).");
      Alert("Expiration must be > 660 seconds");
      StopScript();
      return(-1);
   }
   
   if (MaxLots < 0) {
      Print("Maximum lots must be greater than zero");
      Alert("Maximum lots must be greater than zero");
      StopScript();
      return(-1);
   }
   
   if (HedgeMultiple < 1) {
      Print("Hedge multiple cannot be less than 1");
      Alert("Hedge multiple cannot be less than 1");
      StopScript();
      return(-1);
   }
   
   if (voice_confirmation == true) {
      Print("Voice confirmation is enabled");
   } else {
      Print("Voice confirmation is turned off");
   }
   
   if (IsTradeAllowed() == false) {
      Print("Trading is not permitted");
      StopScript();
   }

   // Must initialize a session with the DLL-API to hold transfer/trade parameters between MT4
   //    and Forex Raptor Freeware windows application.
   session = FindExistingSession(AccountNumber(),WindowHandle(Symbol(),0),Symbol());
   if (session == 0) {
      //session = Initialize(AccountNumber(),WindowHandle(Symbol(),0),Symbol());
      session = Initialize(AccountNumber(),WindowHandle(Symbol(),0),Symbol(),Currency1,Currency2,Currency3);
      if (session == -1) {
         Alert("Maximum Allowable Sessions reached. Stopping Expert!");
         StopScript();
         return(-1);
      } else {
         Print("Opening new Session # ",session);
      }
   } else {
      Print("Found existing session for this window: #",session);
   }

   Print("Saving account information...");
   SaveAccountInfo(session,AccountNumber(),AccountBalance(),AccountEquity(),AccountLeverage());                                
   Print("Saving currency session information...");
   SaveCurrencySessionInfo(session,Symbol(),WindowHandle(Symbol(),0),Period(),AccountNumber());

   SaveMarginInfo(session,Symbol(),WindowHandle(Symbol(),0),
                  MarketInfo(Symbol(),MODE_MARGININIT),
                  MarketInfo(Symbol(),MODE_MARGINMAINTENANCE),
                  MarketInfo(Symbol(),MODE_MARGINHEDGED),
                  MarketInfo(Symbol(),MODE_MARGINREQUIRED),
                  MarketInfo(Symbol(),MODE_MARGINCALCMODE));
   
   SaveMarketInfo(session,AccountNumber(),
                              AccountLeverage(),
                              Symbol(),
                              MarketInfo(Symbol(),MODE_POINT),
                              MarketInfo(Symbol(),MODE_DIGITS),
                              MarketInfo(Symbol(),MODE_SPREAD),
                              MarketInfo(Symbol(),MODE_STOPLEVEL));

   //Print("rc=",rc);
   SaveMarginInfo(session,Symbol(),WindowHandle(Symbol(),0),MarketInfo(Symbol(),MODE_MARGININIT),
                              MarketInfo(Symbol(),MODE_MARGINMAINTENANCE),
                              MarketInfo(Symbol(),MODE_MARGINHEDGED),
                              MarketInfo(Symbol(),MODE_MARGINREQUIRED),
                              MarketInfo(Symbol(),MODE_MARGINCALCMODE));

   //Alert("Sending historical prices");

   double history[][6];
   ArrayCopyRates(history);
   SaveHistory(session,Symbol(),history,Bars,WindowHandle(Symbol(),0)); 

   //double open = RetrieveHistoricalOpen(session,0);

   Sleep(3000);
   
   ArrayCopyRates(history,Currency1);
   //SaveHistoryCcy1(session,Currency1,history,Bars,WindowHandle(Symbol(),0)); 

   Sleep(3000);

   ArrayCopyRates(history,Currency2);
   //SaveHistoryCcy2(session,Currency2,history,Bars,WindowHandle(Symbol(),0)); 

   Sleep(3000);

   ArrayCopyRates(history,Currency3);
   //SaveHistoryCcy3(session,Currency3,history,Bars,WindowHandle(Symbol(),0)); 

   SetBidAsk(session,Bid,Ask,Close[0],Volume[0]);
   
   SendResponse(session,0,0,"Session started successfully",0);

   if (voice_confirmation == true) {
      msg = "Forex General is now ready on " + CurrencyToSpeech();
      gSpeak(msg, -10, 100);
   }
   
   StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
   
   
   if (MagicNumber == 0) {
       GlobalNameRandomNumber = StringConcatenate(GlobalNamePrefix,"index");
       Print("Magic number index global variable = ",GlobalNameRandomNumber);
       GenerateMagicNumber(10000,50000);
   }
   Print("Magic number: ",MagicName,"=",MagicNumber);
   
   SetSwapRateLong(session,MarketInfo(Symbol(),MODE_SWAPLONG));
   SetSwapRateShort(session,MarketInfo(Symbol(),MODE_SWAPSHORT));
   
   Alert(StringConcatenate("Forex General on ",Symbol()," is ready for trading"));   
      
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
   
   Print("Closing Metatrader session # ",session);
   
   if (DeInitialize(session) != 0) {
      Print(Symbol()," was not properly deinitialize. Session count=",GetSessionCount());
      msg = "four rex general could not be removed for " + CurrencyToSpeech();
   } else {
      Print(Symbol()," deinitialized successfully! Session count=", GetSessionCount());
      msg = "four rex general has been successfully removed for " + CurrencyToSpeech();
   }   
   if (voice_confirmation == true) gSpeak(msg, -10, 100);
   
   GlobalVariablesDeleteAll(GlobalNamePrefix);
         
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double price=0,lots=0,stoploss=0,takeprofit=0;
   string ccypair;
   //double askprice,buyprice;
   datetime expiration=0;
   int i,ticket;
   int errnum=0;
   
   if (session == -1) return;
   
   int cmd = GetTradeOpCommand(session);
   
   
   if (cmd != -1 && cmd != 11) {
      price = GetTradePrice(session);
      lots = GetTradeLots(session);
      stoploss = GetTradeStoploss(session);
      takeprofit = GetTradeTakeprofit(session);
      expiration = TimeCurrent() + Expiry;
      ticket = 0;
      DecrementQueuePosition(session);
      
      GlobalVariableSet(StringConcatenate(MagicName,"Price"),price);
      GlobalVariableSet(StringConcatenate(MagicName,"Lots"),lots);
      GlobalVariableSet(StringConcatenate(MagicName,"StopLoss"),stoploss);
      GlobalVariableSet(StringConcatenate(MagicName,"TakeProfit"),takeprofit);
      GlobalVariableSet(StringConcatenate(MagicName,"TradeCommand"),cmd);
   }

   if (TradeEnabled == true) {
      // if there are any orders already opened then prevent REX from opening any more!
      if (OTG == true) {
         if (OrdersTotal() > 0) {
            for (i=0;i<OrdersTotal();i++) {
               if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true) 
               {
                  if (OrderMagicNumber() == MagicNumber) {
                     TrailOrder(); 
                     // update the balanace, equity info   
                     SendResponse(session,0,0,"One Trade Globally (OTG) is ACTIVE. Trade rejected other trades opened.",OrderTicket());
                     SaveAccountInfo(session,AccountNumber(),AccountBalance(),AccountEquity(),AccountLeverage()); 
                     ResetTradeCommand(session);
                     return;
                  }
               }
            }
            SendResponse(session,0,0,"One Trade Globally (OTG) is ACTIVE. Trade rejected other trades opened.",0);
         }
      } else if (OTS == true) {
         //int tmp;
         for (i=0;i<OrdersTotal();i++) {
            if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true)
            {
               if (OrderMagicNumber() == MagicNumber) {
                  TrailOrder(); 
                  // update the balanace, equity info   
                  SendResponse(session,0,0,"One Trade per Currency Session (OTS) is ACTIVE. Trade rejected for the currency, other trades opened.",OrderTicket());
                  SaveAccountInfo(session,AccountNumber(),AccountBalance(),AccountEquity(),AccountLeverage());                                
                  ResetTradeCommand(session);
                  return;            
               }
            }
         }
      }

      if (AccountEquity() < MinEquity) {
         SendResponse(session,0,0,"Trading temporarily disabled when equity is less than user-defined minimum of "+DoubleToString(MinEquity)+". Trade discarded!",0);
         Print("Trading temporarily disabled when equity is less than user-defined minimum. Trade discarded!");
         return;
      }

      double LotsSize = MarketInfo(Symbol(),MODE_LOTSIZE);
      double LotsStep = MarketInfo(Symbol(),MODE_LOTSTEP);
      double MaxLot = MarketInfo(Symbol(),MODE_MAXLOT);
      double MinLot = MarketInfo(Symbol(),MODE_MINLOT);

      if (MoneyManagement) {
         Leverage=AccountLeverage();
         lots=MathFloor((AccountBalance()*Risk*(Leverage/100))/LotsSize*MinLot)*MinLot;
      } else {
         if (lots > MaxLot) lots = MaxLot;
         if (lots < MinLot) lots = MinLot;
      }

      if (lots > MaxLots) {
         Print("Trade rejected by Forex General as lots exceed maximum lots. Increase your Maximum Lots greater than ",lots);
         SendResponse(session,0,0,"Hedge Trade rejected by Forex General as hedge multiple lots exceed the max lots of "+DoubleToString(lots),0);
         return;
      }
   
      if (Hedge == true && (lots*HedgeMultiple) > MaxLots) {
         Print("Hedge Trade rejected by Forex General as hedge multiple lots exceed the max lots. Increase your Maximum Lots greater than ",lots*2);
         SendResponse(session,0,0,"Hedge Trade rejected by Forex General as hedge multiple lots exceed the max lots of "+DoubleToString(lots*2),0);
         return;
      }

      bool old_hedge = Hedge;
      if (Hedge == true) {
         double atr = iATR(NULL,0,14,0);
         double rank = atr/Bid * 100;
   
         switch(HedgeRisk) {
            case 0:  // Low risk hedging opportunity
               if (rank >= 0.63) Hedge=false; else Hedge=true;
               break;
            case 1:  // Medium risk hedging opportunity
               if (rank >= 0.77) Hedge=false; else Hedge=true;
               break;
            default: // all others is high risk hedging opportunity
               break;
         }
      }
      
      if (cmd != 11) {
      switch(cmd) {
         case OP_BUY:
            if (Hedge == true) {
               ticket = OrderSend(Symbol(),OP_BUY,lots*HedgeMultiple,Ask,slippage,0,0,"ForexGeneral-MarketHedgeBUY",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }              
               ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,0,0,"ForexGeneral-MarketHedgeSELL",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               if (errnum == 0) SendResponse(session,0,0,"Market Hedge Trade(s) accepted.",ticket);
            } else {
               ticket = OrderSend(Symbol(),cmd,lots,Ask,slippage,stoploss,takeprofit,"ForexGeneral-MarketBuy",MagicNumber,0,Blue);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)," for Market Buy => price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit,", expiration=",TimeToStr(expiration)); 
                  msg = "error on market buy for " + CurrencyToSpeech();
               } else {
                  msg = "market buy on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
            }
            break;
         case OP_SELL:
            if (Hedge == true) {
               ticket = OrderSend(Symbol(),OP_SELL,lots*HedgeMultiple,Bid,slippage,0,0,"ForexGeneral-MarketHedgeSELL",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,slippage,0,0,"ForexGeneral-MarketHedgeBUY",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               if (errnum == 0) SendResponse(session,0,0,"Market Hedge Trade(s) accepted.",ticket);
            } else {
               ticket = OrderSend(Symbol(),cmd,lots,Bid,slippage,stoploss,takeprofit,"ForexGeneral-MarketSell",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)," for Market Sell => price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit,", expiration=",TimeToStr(expiration)); 
                  msg = "error on market sell for " + CurrencyToSpeech();
               } else {
                  msg = "market sell on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
            }
            break;
         case OP_BUYLIMIT:
            if (Hedge == true) {
               ticket = OrderSend(Symbol(),OP_BUYLIMIT,lots*HedgeMultiple,price,slippage,0,0,"ForexGeneral-HedgeBUYLIMIT",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               ticket = OrderSend(Symbol(),OP_SELLSTOP,lots,price,slippage,0,0,"ForexGeneral-HedgeSLELLSTOP",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               if (errnum == 0) SendResponse(session,0,0,"Entry Hedge Trade(s) accepted.",ticket);
            } else {
               ticket = OrderSend(Symbol(),cmd,lots,price,slippage,stoploss,takeprofit,"ForexGeneral-BuyLimit",MagicNumber,expiration,LightBlue);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)," for Buy Limit => price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit,", expiration=",TimeToStr(expiration)); 
                  msg = "error on buy limit for " + CurrencyToSpeech();
               } else {
                  msg = "buy limit on " + CurrencyToSpeech(); 
               }
               Print("BUYLIMIT: session=",session,", cmd=",cmd,", price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit);
               CheckForError(ticket,errnum,"Entry Buy Limit Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
            }
            break;
         case OP_BUYSTOP:
            if (Hedge == true) {
               ticket = OrderSend(Symbol(),OP_BUYSTOP,lots*HedgeMultiple,price,slippage,0,0,"ForexGeneral-HedgeBUYSTOP",MagicNumber,expiration,Blue);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               ticket = OrderSend(Symbol(),OP_SELLLIMIT,lots,price,slippage,0,0,"ForexGeneral-HedgeSELLLIMIT",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               if (errnum == 0) SendResponse(session,0,0,"Entry Hedge Trade(s) accepted.",ticket);
            } else {
               ticket = OrderSend(Symbol(),cmd,lots,price,slippage,stoploss,takeprofit,"ForexGeneral-BuyStop",MagicNumber,expiration,DarkBlue);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)," for Buy Stop => price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit,", expiration=",TimeToStr(expiration)); 
                  msg = "error on buy stop for " + CurrencyToSpeech();
               } else {
                  msg = "buy stop on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Entry Buy Stop Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
            }
            break;
         case OP_SELLLIMIT:
            if (Hedge == true) {
               ticket = OrderSend(Symbol(),OP_SELLLIMIT,lots*HedgeMultiple,price,slippage,0,0,"ForexGeneral-HedgeSELLLIMIT",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               ticket = OrderSend(Symbol(),OP_BUYSTOP,lots,price,slippage,0,0,"ForexGeneral-HedgeBUYSTOP",MagicNumber,expiration,Blue);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               if (errnum == 0) SendResponse(session,0,0,"Entry Hedge Trade(s) accepted.",ticket);
            } else {
               ticket = OrderSend(Symbol(),cmd,lots,price,slippage,stoploss,takeprofit,"ForexGeneral-SellLimit",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)," for Sell Limit => price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit,", expiration=",TimeToStr(expiration)); 
                  msg = "error on sell limit for " + CurrencyToSpeech();
               } else {
                  msg = "sell limit on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Entry Sell Limit Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
            }
            break;
         case OP_SELLSTOP:
            if (Hedge == true) {
               ticket = OrderSend(Symbol(),OP_SELLSTOP,lots*HedgeMultiple,price,slippage,0,0,"ForexGeneral-HedgeSELLSTOP",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               ticket = OrderSend(Symbol(),OP_BUYLIMIT,lots,price,slippage,0,0,"ForexGeneral-HedgeBUYLIMIT",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  SendResponse(session,errnum,0,ErrorDescription(errnum),0);
               }
               if (errnum == 0) SendResponse(session,0,0,"Entry Hedge Trade(s) accepted.",ticket);
            } else {
               ticket = OrderSend(Symbol(),cmd,lots,price,slippage,stoploss,takeprofit,"ForexGeneral-SellStop",MagicNumber,expiration,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)," for Sell Stop => price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit,", expiration=",TimeToStr(expiration)); 
                  msg = "error on sell stop for " + CurrencyToSpeech();
               } else {
                  msg = "sell stop on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Entry Sell Stop Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
            }
            break;
         default:
          break;
        }
      } else {
            // no trade, check for TAC trade
            /*
              First Currency Pair
            */
            RefreshRates();

            cmd = GetTradeOpCommand1(session);
            if (cmd != -1 && cmd != 10) {
               ccypair = GetTradeCurrency(session);
               if (MarketInfo(ccypair,MODE_LOTSIZE) > 0) {
                  lots = GetTradeLots(session) / MarketInfo(ccypair,MODE_LOTSIZE);
                  ticket = SendOrder(ccypair,cmd,lots);
               }
            }

            /*
               Second Currency Pair
            */
            RefreshRates();

            cmd = GetTradeOpCommand2(session);
            if (cmd != -1 && cmd != 10) {
               ccypair = GetTradeCurrency2(session);
               if (MarketInfo(ccypair,MODE_LOTSIZE) > 0) {
                  lots = GetTradeLots2(session) / MarketInfo(ccypair,MODE_LOTSIZE);
                  ticket = SendOrder(ccypair,cmd,lots);
               }
            }

            /*
               Third Currency Pair
            */
            RefreshRates();

            cmd = GetTradeOpCommand3(session);
            if (cmd != -1 && cmd != 10) {
               ccypair = GetTradeCurrency3(session);
               if (MarketInfo(ccypair,MODE_LOTSIZE) > 0) {
                  lots = GetTradeLots3(session) / MarketInfo(ccypair,MODE_LOTSIZE);
                  ticket = SendOrder(ccypair,cmd,lots);
               }
            }
      }
      // Update any trailing stops for this currency pair
      if (OrdersTotal() > 0) {
         for (i=0;i<OrdersTotal();i++) {
            if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true) {
               if (OrderMagicNumber() == MagicNumber) {
                  TrailOrder();
               }
            }
         }
      }
      Hedge = old_hedge;
   }   

   double profit=0;


   // Calculate the total profit for these currencies associated with the magic number
   if (OrdersTotal() > 0) {
      for (i=0;i<OrdersTotal();i++) {
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true) {
            if (OrderMagicNumber() == MagicNumber) {
               profit = profit + OrderProfit();
               //TrailOrder();
            }
         }
      }
      if (profit > MinimumProfit) {
         close_all = true; // set a flag, in case the close order does not take, and recycles.
         for (i=0;i<OrdersTotal();i++) {
            if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true) {
               if (OrderMagicNumber() == MagicNumber) {
                  if (OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,0))
                  {
                  }
               }
            }
         }
      }
   }
   
   if (close_all == true) {
      if (OrdersTotal() > 0) {
         for (i=0;i<OrdersTotal();i++) {
            if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true) {
               if (OrderMagicNumber() == MagicNumber) {
                  if (OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,0))
                  {
                  }
               }
            }
         }
      } else {
        // have to reset the close all flag otherwise new trades are closed immediately
        close_all = false;
      }
   }

   // update the balanace, equity info   
   SaveAccountInfo(session,AccountNumber(),AccountBalance(),AccountEquity(),AccountLeverage());                                
   SetBidAsk(session,Bid,Ask,Close[0],Volume[0]);
   
   
   ResetTradeCommand(session);
   
   cmd = -1;      
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

//
// Send Order - put this in a separate function to produce a delay as not all orders were being opened.
//
int SendOrder(string ccypair,int cmd,double lots) {
      int ticket=0;
      int errnum=0;
      double askprice = MarketInfo(ccypair,MODE_ASK);
      double buyprice = MarketInfo(ccypair,MODE_BID);

      if (TradeEnabled == true) {
         switch(cmd) {
            case OP_BUY:
               ticket = OrderSend(ccypair,cmd,lots,askprice,slippage,0,0,"ArbCalc-MARKET_BUY",MagicNumber,0,Blue);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  msg = "error on market buy for " + CurrencyToSpeech();
               } else {
                  msg = "market buy on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
               break;
            case OP_SELL:
               ticket = OrderSend(ccypair,cmd,lots,buyprice,slippage,0,0,"ArbCalc-MARKET_SELL",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
                  msg = "error on market sell for " + CurrencyToSpeech();
               } else {
                  msg = "market sell on " + CurrencyToSpeech(); 
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
               if (voice_confirmation == true) gSpeak(msg, -10, 100);
               break;
         }
      }
      return (ticket);
}

//
// Generates a random magic number
//
void GenerateMagicNumber(int low_range,int high_range) 
{
   int pass=0;
   double index;
   
   if (!GlobalVariableCheck(GlobalNameRandomNumber)) {
      GlobalVariableSet(GlobalNameRandomNumber,0);
   }
   
   index = GlobalVariableGet(GlobalNameRandomNumber); 
      
   while(!pass) {
      MagicName = StringConcatenate(GlobalNamePrefix,Symbol(),index);
      if (GlobalVariableCheck(MagicName)) {
         index = index + 1;
      } else {
         GlobalVariableSet(GlobalNameRandomNumber,index);
         GlobalVariableSet(MagicName,MagicNumber);
         pass=1;
      }
   }

   int globalcount;
   pass=0;
   
   while (!pass) {
      int rand1= MathRand()/32767;
      int rand2=rand1*(high_range-low_range) + low_range;
      MagicNumber = rand2;
      globalcount = 0;
      
      for (int i=0;i<GlobalVariablesTotal();i++) {
         if (GlobalVariableGet(GlobalVariableName(i)) != MagicNumber) {
            globalcount = globalcount + 1;
         }
      }
      
      if (globalcount == GlobalVariablesTotal()) {
          GlobalVariableSet(MagicName,MagicNumber);
          pass=1;
      }
   }
}

//
// Trailing stop routine
//  
void TrailOrder()
{
   if (TrailingStop>0)
   {
      int type = OrderType();

      if (TrailingStop < StopLevel) TrailingStop = StopLevel;
      
      if(type==OP_BUY)
      {
         if(Bid-OrderOpenPrice()>(Point*TrailingStop))
         {
            if(OrderStopLoss()<Bid-(Point*TrailingStop))
            {
               if (OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(Point*TrailingStop),OrderTakeProfit(),0,Green)) 
               {
               }
            }
         }
      }
      if(type==OP_SELL)
      {
         if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
         {
            if((OrderStopLoss()>(Ask+(Point*TrailingStop))) || (OrderStopLoss()==0))
            {
               if (OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(Point*TrailingStop),OrderTakeProfit(),0,Red))
               {
               }
            }
         }
      }
   }
}

//
// Checks for an error and sends to REX
//  
void CheckForError(int ticket,int errnum,string _msg)
{
   string error;
   if (ticket == -1) 
   {
      error = ErrorDescription(errnum);
      SendResponse(session,errnum,0,error,ticket);
   }
   else
   {
      SendResponse(session,errnum,0,_msg,ticket);
   }
}

//
// Converts Error code to text string 
//
string ErrorDescription(int rcerror)
{
   switch(rcerror) {
      case ERR_NO_ERROR: return("No error returned"); //ERR_NO_ERROR 0 No error returned. 
      case ERR_NO_RESULT: return("No error returned, but the result is unknown."); 
      case ERR_COMMON_ERROR: return("Common error. ");
      case ERR_INVALID_TRADE_PARAMETERS: return("Invalid trade parameters. ");
      case ERR_SERVER_BUSY: return("Trade server is busy. ");
      case ERR_OLD_VERSION: return("Old version of the client terminal. ");
      case ERR_NO_CONNECTION: return("No connection with trade server. ");
      case ERR_NOT_ENOUGH_RIGHTS: return("Not enough rights. ");
      case ERR_TOO_FREQUENT_REQUESTS: return("Too frequent requests. ");
      case ERR_MALFUNCTIONAL_TRADE: return("Malfunctional trade operation."); 
      case ERR_ACCOUNT_DISABLED: return("Account disabled. ");
      case ERR_INVALID_ACCOUNT: return("Invalid account. ");
      case ERR_TRADE_TIMEOUT: return("Trade timeout. ");
      case ERR_INVALID_PRICE: return("Invalid price. ");
      case ERR_INVALID_STOPS: return("Invalid stops. ");
      case ERR_INVALID_TRADE_VOLUME: return("Invalid trade volume. ");
      case ERR_MARKET_CLOSED: return("Market is closed. ");
      case ERR_TRADE_DISABLED: return("Trade is disabled. ");
      case ERR_NOT_ENOUGH_MONEY: return("Not enough money. ");
      case ERR_PRICE_CHANGED: return("Price changed. ");
      case ERR_OFF_QUOTES: return("Off quotes. ");
      case ERR_BROKER_BUSY: return("Broker is busy. ");
      case ERR_REQUOTE: return("Requote. ");
      case ERR_ORDER_LOCKED: return("Order is locked. ");
      case ERR_LONG_POSITIONS_ONLY_ALLOWED: return("Long positions only allowed. ");
      case ERR_TOO_MANY_REQUESTS: return("Too many requests. ");
      case ERR_TRADE_MODIFY_DENIED: return("Modification denied because order too close to market. ");
      case ERR_TRADE_CONTEXT_BUSY: return("Trade context is busy. ");
      case ERR_TRADE_EXPIRATION_DENIED: return("Expirations are denied by broker. ");
      case ERR_TRADE_TOO_MANY_ORDERS: return("The amount of open and pending orders has reached the limit set by the broker. ");
  }
  return("Unknown error");
}


string CurrencyToSpeech() 
{
   if (Symbol() == "EURUSD") return ("euro dollar");
   if (Symbol() == "USDCHF") return ("swissie");
   if (Symbol() == "GBPUSD") return ("cable");
   if (Symbol() == "USDJPY") return ("dollar yen");
   if (Symbol() == "USDCAD") return ("green back mountie");
   if (Symbol() == "NZDUSD") return ("kiwie");
   if (Symbol() == "AUDUSD") return ("aussie");
   if (Symbol() == "GBPJPY") return ("sterling yen");
   if (Symbol() == "CHFJPY") return ("swiss yen");
   if (Symbol() == "EURJPY") return ("euro yen");
   if (Symbol() == "EURGBP") return ("euro sterling");
   if (Symbol() == "EURCHF") return ("euro swiss");
   if (Symbol() == "GBPCHF") return ("sterling swiss");
   if (Symbol() == "AUDJPY") return ("aussie yen");
   if (Symbol() == "EURCAD") return ("euro canadian");
   if (Symbol() == "EURAUD") return ("euro aussie");
   if (Symbol() == "AUDCAD") return ("aussie canadian");
   if (Symbol() == "AUDNZD") return ("aussie kiwi");
   if (Symbol() == "NZDJPY") return ("kiwi yen");
   return("this currency pair");
}  
//+------------------------------------------------------------------+
