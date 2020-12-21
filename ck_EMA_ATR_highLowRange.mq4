//+------------------------------------------------------------------+
//|                                          ck_EMA_ATR_highLowRange |
//|                                           Copyright 2020, ckwong |
//|                                 https://github.com/ckwong1204/ea |
//+------------------------------------------------------------------+
#property copyright   "ck 2020-12-20"
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#define MAGICMA  20201220
input double Lots          =0.01;
input int    atrPeriod     =24;
input int    MovingShift   =1;

input int   emaPeriod20    =24;
input int   emaPeriod50    =48;
input int   emaPeriod70    =144;

input int highLowRangePeriod = 12; //hour

input double takeProfitRatio = 6;
input double stopLossRatio = 3;


double ema20;
double ema50;
double ema70;
double atr;

//| Calculate open positions
int CalculateCurrentOrders(string symbol) {
   int buys=0,sells=0;
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA) {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
      }
   }
   if(buys>0) return(buys);
   else       return(-sells);
}
double LotsOptimized() {
   return 0.01;
}

void buyOrderSendWithTlSp(double price) {
   double takeProfit = price + takeProfitRatio * atr;
   double stopLoss   = price - stopLossRatio * atr;
   const string comment= "long" + stopLoss + "-" + takeProfit;

   int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),price,3,stopLoss, takeProfit,comment,MAGICMA,0,Green);

   if(ticket>0) {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
         Print("buy order opened : ",OrderOpenPrice());
   } else
      Print("Error opening BUY order : ",GetLastError());
}

void sellOrderSendWithTlSp(double price) {
   double takeProfit = price - takeProfitRatio * atr;
   double stopLoss   = price + stopLossRatio * atr;
   string comment= "short" + stopLoss + "-"+takeProfit;

   int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),price,3,stopLoss, takeProfit,comment,MAGICMA,0,Red);

   if(ticket>0) {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
         Print("sell order opened : ",OrderOpenPrice());
   } else
      Print("Error opening BUY order : ",GetLastError());
}

void OnTick() {
   //--- check for history and trading
   if(Bars<atrPeriod || IsTradeAllowed()==false)
      return;

   //--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) {
      ema20 =iMA( NULL,PERIOD_H1,emaPeriod20,MovingShift,MODE_EMA,PRICE_CLOSE,0);
      ema50 =iMA( NULL,PERIOD_H1,emaPeriod50,MovingShift,MODE_EMA,PRICE_CLOSE,0);
      ema70 =iMA( NULL,PERIOD_H1,emaPeriod70,MovingShift,MODE_EMA,PRICE_CLOSE,0);
      
      atr   =iATR(NULL,PERIOD_H1, atrPeriod,MovingShift);
      double periodHigh =High[iHighest(Symbol(),PERIOD_H1,MODE_HIGH,highLowRangePeriod,1)];
      double periodLow  =Low [iHighest(Symbol(),PERIOD_H1,MODE_LOW, highLowRangePeriod,1)];

      bool ema_gt_20_50_70 = ema20 >= ema50 && ema50 >= ema70;
      bool ema_lt_20_50_70 = ema20 <= ema50 && ema50 <= ema70;

      bool ema_gt_20_50_150 = ema20 >= ema50 && ema50 >= ema150;
      bool ema_lt_20_50_150 = ema20 <= ema50 && ema50 <= ema150;

      bool buyCondition =  Close[0]>ema20 && Close[0]>periodHigh && ema_gt_20_50_70; //&& atr < 0.0015;
      //bool sellCondition = Close[0]<ema20 && Close[0]<periodHigh && ema_lt_20_50_70; //&& atr < 0.0003;

      if(buyCondition) {
         buyOrderSendWithTlSp(Ask);
      }
      // else if(sellCondition) {
      //    sellOrderSendWithTlSp(Bid);
      // }
      
   }
}
//+------------------------------------------------------------------+
