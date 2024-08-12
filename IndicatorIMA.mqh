/*
  BotTrade.mqh
  CopyRight 2024, Sidjeanp
  https://www.sidjeanp.com
*/

#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"
class CIndicatorIMA {
private:

protected:
  string mSymbol;
  int mTimeFrame;
  
  int mHandle;
  double mBuffer[];

public:
  CIndicatorIMA();
  ~CIndicatorIMA();
   
  bool usValid() { return(mHandle!=INVALID_HANDLE);}
  int  GetArray(int bufferNumber, int start, int count, double &arr[]);
  virtual double GetValue(int bufferNumber, int index);
  
};

CIndicatorIMA::CIndicatorIMA() {
}

CIndicatorIMA::~CIndicatorIMA() {
}
