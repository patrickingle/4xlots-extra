//+------------------------------------------------------------------+
//|                                                       4xlots.mqh |
//|   Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash |
//|                                           https://www.4xlots.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019-2020, PressPage Entertainment Inc DBA RedeeCash"
#property link      "https://www.4xlots.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define ENDPOINT    "https://api.4xlots.com/wp-json/v1/lots_optimize"

extern double Deposit=200;
extern bool Preserve=false;
extern string AccessKey="[REPLACE WITH YOUR ACCESSKEY FROM 4XLOTS.COM]";
extern int LeverageOverride=200;
extern double MaxLossForceClose = -1.00;

#import "4xlotslib.ex4"
   double LotsOptimize(double deposit,int preserve);
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
   int    RGB(int red_value,int green_value,int blue_value);
   bool   CompareDoubles(double number1,double number2);
   string DoubleToStrMorePrecision(double number,int precision);
   string IntegerToHexString(int integer_number);
#import 
