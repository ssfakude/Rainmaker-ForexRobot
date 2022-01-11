//+------------------------------------------------------------------+
//|                                                     simphiwe.mq5 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
/*
NB notes and tricks
Press Ctrl+D to view buffer on mt5
Press Ctrl+R to Test EA on mt5

1 pip = 10 points

Ctrl+D view files
F1 to for func ref

*/
#property version   "1.00"
#include <Trade/Trade.mqh>// For trading operation
//for the one h1
int handleTrendMaFast; // Green
int handleTrendMaSlow; //Red

// for the 5 minutes
int handleMaFast; // Grean
int handleMaMiddle;// Blue
int handleMaSlow;// Red

CTrade trade; // Create obj
int eMagic_num = 2;

int OnInit()
  {
  // IMA-  Indicator Moving Average (builtin func)
  //_symbol pairname, where the EA is applied
   handleTrendMaFast = iMA(_Symbol, PERIOD_H1,8,0, MODE_EMA,PRICE_CLOSE);
   handleTrendMaSlow = iMA(_Symbol, PERIOD_H1,21,0, MODE_EMA,PRICE_CLOSE);
   
   handleMaFast = iMA(_Symbol, PERIOD_M5,8,0, MODE_EMA,PRICE_CLOSE);
   handleMaMiddle = iMA(_Symbol, PERIOD_M5, 13, 0, MODE_EMA, PRICE_CLOSE);
   handleMaSlow = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {


   
  }

void OnTick()
  {
  trade.SetExpertMagicNumber(eMagic_num); // this is to mark this EA, so its unique
  // Every EA needs its own magic number to identify its trades
   double maTrendFast[], maTrendSlow[];
   CopyBuffer(handleTrendMaFast,0,0,1,maTrendFast);
   CopyBuffer(handleTrendMaSlow,0,0,1,maTrendSlow);
   
   double MaSlow[], MaMiddle[], MaFast[];
   CopyBuffer(handleMaFast, 0,0,1,MaFast);
   CopyBuffer(handleMaMiddle, 0,0,1,MaMiddle);
   CopyBuffer(handleMaSlow, 0,0,1,MaSlow);
   
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); // Current price
   
   int trendDirection = 0;
   if (maTrendFast[0] > maTrendSlow[0] && bid > maTrendFast[0]){
      trendDirection = 1;
   }
   else if(maTrendFast[0] < maTrendSlow[0] && bid < maTrendFast[0]){
   trendDirection = -1;
   }
   
   int positions = 0;
   for( int i = PositionsTotal()-1; i >=0; i--){
      ulong posTicket = PositionGetTicket(i);
      if(PositionSelectByTicket(posTicket)){
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == eMagic_num){
            positions++;
            
            }
      }
   }
   
      int orders = 0;
   for( int i = OrdersTotal()-1; i >=0; i--){
      ulong orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket)){
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == eMagic_num){
         if (OrderGetInteger(ORDER_TIME_SETUP) < TimeCurrent() -30 * PeriodSeconds(PERIOD_M1)){
         // If it takes more than 30 minutes to position an order then abort!
         // This means that there is no trend at that moment
         trade.OrderDelete(orderTicket);
         }
            orders++;}
      }
   }
   
   
   
   if (trendDirection == 1){
      if(MaFast[0] > MaMiddle[0] && MaMiddle[0] > MaSlow[0]){
         if (bid <= MaFast[0] ){
          Print("Buy signal");
          if(positions + orders <= 0){
          // order price
          int indexHighest = iHighest(_Symbol, PERIOD_M5,MODE_HIGH,5,1); // get higst candle from the last 5 candle 
          double highPrice =iHigh(_Symbol,PERIOD_M5,indexHighest); // return the price of highest candle
          highPrice = NormalizeDouble(highPrice, _Digits);// Round off the double to be same as in the charts
          //Stop loss
          double sl = iLow(_Symbol,PERIOD_M5,0) -30 * _Point; // trigger bar + 3 pips
          sl = NormalizeDouble(sl, _Digits);
          // Take profit
          double tp = highPrice + (highPrice - sl);
          tp = NormalizeDouble(tp, _Digits);
          trade.BuyStop(0.01,highPrice, _Symbol, sl,tp);// buy stop order
          }
          } 
      }
     
   }
   else if (trendDirection == -1){
      if(MaFast[0] < MaMiddle[0] && MaMiddle[0] < MaSlow[0]){
      if (bid >= MaFast[0]  ){
         Print("Sell signal");
         if(positions + orders <= 0){
         int indexLowest = iLowest(_Symbol, PERIOD_M5,MODE_LOW,5,1); // get lowest candle from the last 5 candle 
          double lowestPrice =iLow(_Symbol,PERIOD_M5,indexLowest);
          lowestPrice = NormalizeDouble(lowestPrice, _Digits);// Round off the double to be same as in the charts
          
          //Stop loss
          
          double sl = iHigh(_Symbol,PERIOD_M5,0) + 30 * _Point;
          sl = NormalizeDouble(sl, _Digits);
             // Take profit
          double tp = lowestPrice - (sl - lowestPrice);
          tp = NormalizeDouble(tp, _Digits);
          trade.SellStop(0.01, lowestPrice,_Symbol,sl,tp);
          
          }
         } 
      }
     
   }
  
   Comment("\nFast Trend Ma: ",DoubleToString( maTrendFast[0], _Digits),
   "\nSlow Trend Ma: ",DoubleToString( maTrendSlow[0], _Digits),
   "\nTrend Direction: ", trendDirection,
   "\n",
   "\nFast Ma: ",DoubleToString( maTrendFast[0], _Digits),
   "\nMiddle Ma: ",DoubleToString( MaMiddle[0], _Digits),
   "\nSlow  Ma: ",DoubleToString( maTrendSlow[0], _Digits),
   "\n",
   "\nPositions: ", positions,
   "\nOrders: ", orders);
   

  //Alert("Hello, Millions!");
  }
