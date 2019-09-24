//+------------------------------------------------------------------+
//|                                                 ForexGeneral.mq4 |
//|        Copyright 2019, PressPage Entertainment Inc DBA RedeeCash |
//|                                    https://www.forexgeneral.info |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://www.forexgeneral.info"
#property version   "1.00"
#property strict

#include <4xlots.mqh>
#include <mql4-http.mqh>

//
// Metatrader Error Messages
//
#define ERR_NO_ERROR                      0 //No error returned. 
#define ERR_NO_RESULT                     1 //No error returned, but the result is unknown. 
#define ERR_COMMON_ERROR                  2 //Common error. 
#define ERR_INVALID_TRADE_PARAMETERS      3 //Invalid trade parameters. 
#define ERR_SERVER_BUSY                   4 //Trade server is busy. 
#define ERR_OLD_VERSION                   5 //Old version of the client terminal. 
#define ERR_NO_CONNECTION                 6 //No connection with trade server. 
#define ERR_NOT_ENOUGH_RIGHTS             7 //Not enough rights. 
#define ERR_TOO_FREQUENT_REQUESTS         8 //Too frequent requests. 
#define ERR_MALFUNCTIONAL_TRADE           9 //Malfunctional trade operation. 
#define ERR_ACCOUNT_DISABLED              64 //Account disabled. 
#define ERR_INVALID_ACCOUNT               65 //Invalid account. 
#define ERR_TRADE_TIMEOUT                 128 //Trade timeout. 
#define ERR_INVALID_PRICE                 129 //Invalid price. 
#define ERR_INVALID_STOPS                 130 //Invalid stops. 
#define ERR_INVALID_TRADE_VOLUME          131 //Invalid trade volume. 
#define ERR_MARKET_CLOSED                 132 //Market is closed. 
#define ERR_TRADE_DISABLED                133 //Trade is disabled. 
#define ERR_NOT_ENOUGH_MONEY              134 //Not enough money. 
#define ERR_PRICE_CHANGED                 135 //Price changed. 
#define ERR_OFF_QUOTES                    136 //Off quotes. 
#define ERR_BROKER_BUSY                   137 //Broker is busy. 
#define ERR_REQUOTE                       138 //Requote. 
#define ERR_ORDER_LOCKED                  139 //Order is locked. 
#define ERR_LONG_POSITIONS_ONLY_ALLOWED   140 //Long positions only allowed. 
#define ERR_TOO_MANY_REQUESTS             141 //Too many requests. 
#define ERR_TRADE_MODIFY_DENIED           145 //Modification denied because order too close to market. 
#define ERR_TRADE_CONTEXT_BUSY            146 //Trade context is busy. 
#define ERR_TRADE_EXPIRATION_DENIED       147 //Expirations are denied by broker. 
#define ERR_TRADE_TOO_MANY_ORDERS         148 //The amount of open and pending orders has reached the limit set by the broker. 

//
// External - User variables
//
//extern bool    Debug    = false;
extern string  MTBridgeURL        = "http://localhost:3000/";
extern bool    TradeEnabled       = true;
extern double  MinEquity          = 0;
extern double  MinimumProfit      = 2;
extern bool    MoneyManagement    = false;
extern double  Risk               = 2.5;
extern bool    Hedge              = false;
extern double  HedgeMultiple      = 2;       // Increases the trend side lots by this multple for a hedge trade
extern int     HedgeRisk          = 0;       // 0=low [<0.63%],1=medium[<0.77%],2=high
extern bool    OTS                = false;   // One trade open at a time per currency
extern bool    OTG                = false;    // One trade open at a time for all currencies/charts
extern double  MaxLots            = 1000;    // The maximum lots  
extern double  Expiry             = 172800;  // value is in seconds (660=10 mins; 172800=48 hrs[2 days]
extern int     slippage           = 10;
extern double  TrailingStop       = 50;
//extern bool    AdjustStops        = true;
extern string  name               = "4XITE";
extern bool    voice_confirmation = false;     // turns on voice confirmation after each trade
extern string  Currency1          = "AUDJPYi";
extern string  Currency2          = "CADJPYi";
extern string  Currency3          = "AUDCADi";

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

double   session=-1; 

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
   
   Print(GetDllVersion());

   if (AccountEquity() < MinEquity) {
      Print("Trading is disabled for account balances less than $1000");
      Alert("Trading is disabled. See journal");
      ExpertRemove();
      return(INIT_FAILED);
   }

   if (name == "") {
      Print("Your Name Must be provided to activate Forex Raptor Freeware");
      Alert("You must provide your name");
      ExpertRemove();
      return(INIT_FAILED);
   }
   
   if (Expiry < 660) {
      Print("Expiration cannot be set less than 660 seconds (must be > 11 minutes).");
      Alert("Expiration must be > 660 seconds");
      ExpertRemove();
      return(INIT_FAILED);
   }
   
   if (MaxLots < 0) {
      Print("Maximum lots must be greater than zero");
      Alert("Maximum lots must be greater than zero");
      ExpertRemove();
      return(INIT_FAILED);
   }
   
   if (HedgeMultiple < 1) {
      Print("Hedge multiple cannot be less than 1");
      Alert("Hedge multiple cannot be less than 1");
      ExpertRemove();
      return(INIT_FAILED);
   }
   
   if (IsTradeAllowed() == false) {
      ExpertRemove();
      Print("Trading is not permitted");
   }
   
   session = FindExistingSession(AccountNumber(),Symbol(),ChartGetInteger(0,CHART_WINDOW_HANDLE));
   if (session == 0) {
      session = StringToDouble(Initialize(AccountNumber(),ChartGetInteger(0,CHART_WINDOW_HANDLE),Symbol(),Currency1,Currency2,Currency3));
      if (session == -1) {
         Alert("Maximum Allowable Sessions reached. Removing Expert!");
         ExpertRemove();
         return(INIT_FAILED);
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
   } else {
      Print(Symbol()," deinitialized successfully! Session count=", GetSessionCount());
   }   
  
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double price=0,lots=0,stoploss=0,takeprofit=0;
   string ccypair="";
   //double askprice,buyprice;
   datetime expiration = NULL;
   int i=0,ticket=0;
   int errnum=0;
   
   if (session == -1) return;
   
   int cmd = GetTradeOpCommand(session);
   
   
   if (cmd != -1 && cmd != 11) {
      price = GetTradePrice(session);
      lots = GetTradeLots(session);
      stoploss = GetTradeStoploss(session);
      takeprofit = GetTradeTakeprofit(session);
      expiration = TimeCurrent() + StrToTime(DoubleToStr(Expiry));
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
               if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
                  if (OrderMagicNumber() == MagicNumber) {
                     TrailOrder(); 
                     // update the balanace, equity info   
                     SendResponse(session,0,0,"One Trade Globally (OTG) is ACTIVE. Trade rejected other trades opened.",OrderTicket());
                     SaveAccountInfo(session,AccountNumber(),AccountBalance(),AccountEquity(),AccountLeverage()); 
                     ResetTradeCommand(session);
                     return;
                  }
               } else {
                  SendResponse(session,GetLastError(),0,"Error when selecting order",i);
               }
            }
            SendResponse(session,0,0,"One Trade Globally (OTG) is ACTIVE. Trade rejected other trades opened.",0);
         }
      } else if (OTS == true) {
         //int tmp;
         for (i=0;i<OrdersTotal();i++) {
            if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
               if (OrderMagicNumber() == MagicNumber) {
                  TrailOrder(); 
                  // update the balanace, equity info   
                  SendResponse(session,0,0,"One Trade per Currency Session (OTS) is ACTIVE. Trade rejected for the currency, other trades opened.",OrderTicket());
                  SaveAccountInfo(session,AccountNumber(),AccountBalance(),AccountEquity(),AccountLeverage());                                
                  ResetTradeCommand(session);
                  return;            
               }
            } else {
               SendResponse(session,GetLastError(),0,"Error when selecting order",i);
            }
         }
      }

      if (AccountEquity() < MinEquity) {
         SendResponse(session,0,0,"Trading temporarily disabled when equity is less than user-defined minimum of "+ DoubleToString(MinEquity) +". Trade discarded!",0);
         Print("Trading temporarily disabled when equity is less than user-defined minimum. Trade discarded!");
         return;
      }

      double LotsSize = MarketInfo(Symbol(),MODE_LOTSIZE);
      double LotsStep = MarketInfo(Symbol(),MODE_LOTSTEP);
      double MaxLot = MarketInfo(Symbol(),MODE_MAXLOT);
      double MinLot = MarketInfo(Symbol(),MODE_MINLOT);

      if (MoneyManagement) {
         lots = LotsOptimize(Deposit,Preserve);
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
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
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
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
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
               }
               Print("BUYLIMIT: session=",session,", cmd=",cmd,", price=",price,", lots=",lots,", stoploss=",stoploss,", takeprofit=",takeprofit);
               CheckForError(ticket,errnum,"Entry Buy Limit Trade accepted.");
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
               }
               CheckForError(ticket,errnum,"Entry Buy Stop Trade accepted.");
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
               }
               CheckForError(ticket,errnum,"Entry Sell Limit Trade accepted.");
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
               }
               CheckForError(ticket,errnum,"Entry Sell Stop Trade accepted.");
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
                  if (!OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,0)){
                     SendResponse(session,GetLastError(),0,"Error when closing order",OrderTicket());
                  } else {
                     SendResponse(session,0,0,"Successfull in closing order",OrderTicket());
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
                  if (!OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,0)) {
                     SendResponse(session,GetLastError(),0,"Error when closing order",OrderTicket());
                  } else {
                     SendResponse(session,0,0,"Successfull in closing order",OrderTicket());
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
//+------------------------------------------------------------------+

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
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
               break;
            case OP_SELL:
               ticket = OrderSend(ccypair,cmd,lots,buyprice,slippage,0,0,"ArbCalc-MARKET_SELL",MagicNumber,0,Red);
               if (ticket == -1) {
                  errnum = GetLastError();
                  Print(ErrorDescription(errnum)); 
               }
               CheckForError(ticket,errnum,"Market Trade accepted.");
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
               if (!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(Point*TrailingStop),OrderTakeProfit(),0,Green)) {
                  // Error
                  SendResponse(session,GetLastError(),0,"Error when modifying order",OrderTicket());
               } else {
                  // Success
                  SendResponse(session,0,0,"Successful in modifying order",OrderTicket());
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
               if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(Point*TrailingStop),OrderTakeProfit(),0,Red)) {
                  // Error
                  SendResponse(session,GetLastError(),0,"Error when modifying order",OrderTicket());
               } else {
                  // Success
                  SendResponse(session,0,0,"Successful in modifying order",OrderTicket());
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



//+------------------------------------------------------------------+
//
// Metatrader API Bridge
//
//+------------------------------------------------------------------+
string GetDllVersion() {
   // http://localhost:4353/GetDllVersion
   return httpGET(MTBridgeURL + "GetDllVersion");
}

string Initialize(int acctnum,long handle,string symbol,string ccy1,string ccy2,string ccy3){
   string url = MTBridgeURL + "Initialize/"+ IntegerToString(acctnum) +"."+ IntegerToString(handle) +"." + symbol + "." + ccy1 + "." + ccy2 + "." + ccy3;
   Print(url);
   return httpGET(url);
}
string GetTradeCurrency(double _session){
   return httpGET(MTBridgeURL + "GetTradeCurrency/" + DoubleToString(session));
}
string GetTradeCurrency2(double _session){
   return httpGET(MTBridgeURL + "GetTradeCurrency2/" + DoubleToString(session));
}
string GetTradeCurrency3(double _session){
   return httpGET(MTBridgeURL + "GetTradeCurrency3/" + DoubleToString(session));
}

int FindExistingSession(int acctnum,string symbol,long handle){
   return StrToInteger(httpGET(MTBridgeURL + "FindExistingSession/" + IntegerToString(acctnum) + "." + symbol + "." + IntegerToString(handle)));
}
int DeInitialize(double _session){
   return StrToInteger(httpGET(MTBridgeURL + "DeInitialize/" + DoubleToString(_session)));
}
int GetSessionCount(){
   return StrToInteger(httpGET(MTBridgeURL + "GetSessionCount/"));
}
int SetBidAsk(double index,double bid,double ask,double close,double vol){
   return StrToInteger(httpGET(MTBridgeURL + "SetBidAsk/" + DoubleToString(index) + "." + DoubleToString(bid) + "." + DoubleToString(ask) + "." + DoubleToString(close) + "." + DoubleToString(vol)));
}
int SaveAccountInfo(double _session,int number,double balance,double equity,int leverage){
   return StrToInteger(httpGET(MTBridgeURL + "SaveAccountInfo/" + DoubleToString(_session) + "." + IntegerToString(number) + "." + DoubleToString(balance) + "." + DoubleToString(equity) + "." + DoubleToString(leverage)));
}
int SaveCurrencySessionInfo(double _session,string symbol,long handle,int period,int number){
   return StrToInteger(httpGET(MTBridgeURL + "SaveCurrencySessionInfo/" + DoubleToString(_session) + "." + symbol + IntegerToString(handle) + "." + IntegerToString(period) + "." + IntegerToString(number)));
}
int DecrementQueuePosition(double _session){
   return StrToInteger(httpGET(MTBridgeURL + "DecrementQueuePosition/" + DoubleToString(_session)));
}
int SaveMarketInfo(double _session,int number,int leverage,string symbol,double points,double digits,double spread,double stoplevel){
   return StrToInteger(httpGET(MTBridgeURL + "SaveMarketInfo/" + DoubleToString(_session) + "." + IntegerToString(number) + "." + IntegerToString(leverage) + "." + symbol + "." + DoubleToString(points) + "." + DoubleToString(digits) + "." + DoubleToString(spread) + "." + DoubleToString(stoplevel)));
}
int SaveMarginInfo(double _session,string symbol,long handle,double margininit,double marginmaintenance,double marginhedged,double marginrequired,double margincalcmode){
   return StrToInteger(httpGET(MTBridgeURL + "SaveMarginInfo/" + DoubleToString(_session) + "." + symbol + "." + IntegerToString(handle) + "." + DoubleToString(margininit) + "." + DoubleToString(marginmaintenance) + "." + DoubleToString(marginhedged) + "." + DoubleToString(marginrequired) + "." + DoubleToString(margincalcmode)));
}
int GetTradeOpCommand(double _session){
   return StrToInteger(httpGET(MTBridgeURL + "GetTradeOpCommand/" + DoubleToString(_session)));
}
int GetTradeOpCommand1(double _session){
   return StrToInteger(httpGET(MTBridgeURL + "GetTradeOpCommand1/" + DoubleToString(_session)));
}
int GetTradeOpCommand2(double _session){
   return StrToInteger(httpGET(MTBridgeURL + "GetTradeOpCommand2/" + DoubleToString(_session)));
}
int GetTradeOpCommand3(double _session){
   return StrToInteger(httpGET(MTBridgeURL + "GetTradeOpCommand3/" + DoubleToString(_session)));
}
int SaveHistory(double _session,string symbol,double &rates[][6],int rates_total,long handle){
   return 0; //StrToInteger(httpGET(MTBridgeURL + "SaveHistory/" + DoubleToString(_session) + "." + symbol + "." + rates + "." + IntegerToString(rates_total) + "." + IntegerToString(handle)));
}
int SaveHistoryCcy1(double _session,string symbol,double &rates[][6],int rates_total,long handle){
   return 0; //StrToInteger(httpGET(MTBridgeURL + "SaveHistoryCcy1/" + DoubleToString(_session) + "." + symbol + "." + rates + "." + IntegerToString(rates_total) + "." + IntegerToString(handle)));
}
int SaveHistoryCcy2(double _session,string symbol,double &rates[][6],int rates_total,long handle){
   return 0; //StrToInteger(httpGET(MTBridgeURL + "SaveHistoryCcy2/" + DoubleToString(_session) + "." + symbol + "." + rates + "." + IntegerToString(rates_total) + "." + IntegerToString(handle)));
}
int SaveHistoryCcy3(double _session,string symbol,double &rates[][6],int rates_total,long handle){
   return 0; //StrToInteger(httpGET(MTBridgeURL + "SaveHistoryCcy3/" + DoubleToString(_session) + "." + symbol + "." + rates + "." + IntegerToString(rates_total) + "." + IntegerToString(handle)));
}
double RetrieveHistoricalOpen(double _session,double index){
   return StrToDouble(httpGET(MTBridgeURL + "RetrieveHistoricalOpen/" + DoubleToString(_session) + "." + DoubleToString(index)));
}
int SendResponse(double _session,int errorcode,int respcode,string message,int ticket){
   return StrToInteger(httpGET(MTBridgeURL + "SendResponse/" + DoubleToString(_session) + "." + IntegerToString(errorcode) + "." + IntegerToString(respcode) + "." + message + "." + IntegerToString(ticket)));
}
double GetTradePrice(double _session){
   return StrToDouble(httpGET(MTBridgeURL + "GetTradePrice/" + DoubleToString(_session)));
}
double GetTradeLots(double _session){
   return StrToDouble(httpGET(MTBridgeURL + "GetTradeLots/" + DoubleToString(_session)));
}
double GetTradeLots2(double _session){
   return StrToDouble(httpGET(MTBridgeURL + "GetTradeLots2/" + DoubleToString(_session)));
}
double GetTradeLots3(double _session){
   return StrToDouble(httpGET(MTBridgeURL + "GetTradeLots3/" + DoubleToString(_session)));
}
double GetTradeStoploss(double _session){
   return StrToDouble(httpGET(MTBridgeURL + "GetTradeStoploss/" + DoubleToString(_session)));
}
double GetTradeTakeprofit(double _session){
   return StrToDouble(httpGET(MTBridgeURL + "GetTradeTakeprofit/" + DoubleToString(_session)));
}
void ResetTradeCommand(double _session){
   httpGET(MTBridgeURL + "ResetTradeCommand/" + DoubleToString(_session));
}
void SetSwapRateLong(double _session,double swaprate){
   httpGET(MTBridgeURL + "SetSwapRateLong/" + DoubleToString(_session) + "." + DoubleToString(swaprate));
}
void SetSwapRateShort(double _session,double swaprate){
   httpGET(MTBridgeURL + "SetSwapRateShort/" + DoubleToString(_session) + "." + DoubleToString(swaprate));
}
   
