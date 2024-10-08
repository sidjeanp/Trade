//+------------------------------------------------------------------+
//|                                                    BreakEven.mqh |
//|                                         CopyRight 2024, Sidjeanp |
//|                                         https://www.sidjeanp.com |
//+------------------------------------------------------------------+
#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Sidjeanp/Bot/Utils.mqh>
#include <Sidjeanp/Bot/ISetup.mqh>

class CBreakEven : public ISetup{
private:
  double preco;

  string beLtsTrigger;
  string beLtsStopLoss;
  double beStopGain;

  double precoEntrada;
  double takeProfitCorrente;
  double beTakeProfit;
  
  CTrade bTrade;
  
  double BreakTriggerFaixas[];
  double BreakStopsFaixas[];
  
  int iFaixa;

public:
  CBreakEven(CTrade &ptrade, MBreakEven &pBreakEven);
  CBreakEven();
  ~CBreakEven();
  
  void OnTickEvent(const MqlTick &pTick, ulong pPos, int &pFaixa);
  
  ISetup* CreateInstance() const override {
    return new CBreakEven();
  }
     
  void BreakEven(double preco,ulong pPosition, int &pFaixa);
  void ListaBreakTrigger(string pBeTrigger, double &pArray[]);
  void AtualizaFaixas();

    
 };


CBreakEven::CBreakEven(CTrade &ptrade, MBreakEven &pBreakEven){
  CBreakEven();
  
  bTrade = ptrade;
  
  beStopGain    = pBreakEven.pBeStopGain;
  beLtsStopLoss = pBreakEven.pBeLtsStopLoss;
  beLtsTrigger  = pBreakEven.pBeLtsTrigger;
  
  AtualizaFaixas();
  
}

CBreakEven::CBreakEven(){
  iFaixa = 0;
}

CBreakEven::~CBreakEven(){
}

void CBreakEven::BreakEven(double preco,ulong pPosition, int &pFaixa){
  if(ArraySize(BreakTriggerFaixas)>0){
   //  for(int i = PositionsTotal()-1; i>=0; i--){
         
     if(!PositionSelectByTicket(pPosition)){
       Print("Falha ao selecionar o ticket");
     }
     double precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
     double takeProfitCorrente = PositionGetDouble(POSITION_TP);
     double sl = PositionGetDouble(POSITION_SL);
     double beTakeProfit = beStopGain*_Point;
     double vlrFaixaTrigger = 0;
     double vlrFaixaLoss = 0;
     int proxFaixa = pFaixa;
     int ultFaixa = ArraySize(BreakStopsFaixas)-1;
     
     if(ultFaixa > pFaixa){
       proxFaixa = pFaixa +1;
     }
        
     if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
       vlrFaixaLoss = precoEntrada+(BreakStopsFaixas[proxFaixa]*_Point);
       vlrFaixaTrigger = precoEntrada+(BreakTriggerFaixas[proxFaixa]*_Point);
       if((preco >= vlrFaixaTrigger) && (vlrFaixaLoss > sl)){
         beTakeProfit = precoEntrada+(beStopGain*_Point);
             
         if(bTrade.PositionModify(pPosition,vlrFaixaLoss,beTakeProfit)){
           Print("BreakEven - Sem falha. ResultRetcode: ",bTrade.ResultRetcode(),", RecodeDescription: ", bTrade.ResultRetcodeDescription());
           //beAtivo = true;
           pFaixa++;
         }
         else{
           Print("BreakEven - Com falha. ResultRetcode: ",bTrade.ResultRetcode(),", RecodeDescription: ", bTrade.ResultRetcodeDescription());
         }
       }        
     }
     else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
       vlrFaixaTrigger = precoEntrada-(BreakTriggerFaixas[proxFaixa]*_Point);
       vlrFaixaLoss = precoEntrada-(BreakStopsFaixas[proxFaixa]*_Point);
       if((preco <= vlrFaixaTrigger) && ((vlrFaixaLoss < sl) || (0.0 == sl))){
         beTakeProfit = precoEntrada-(beStopGain*_Point);       
             
         if(bTrade.PositionModify(pPosition,vlrFaixaLoss,beTakeProfit*_Point)){
           Print("BreakEven - Sem falha. ResultRetcode: ",bTrade.ResultRetcode(),", RecodeDescription: ", bTrade.ResultRetcodeDescription());
           //beAtivo = true;
           pFaixa++;
         }
         else{
           Print("BreakEven - Com falha. ResultRetcode: ",bTrade.ResultRetcode(),", RecodeDescription: ", bTrade.ResultRetcodeDescription());
         }
       }     
     }
   }
  
}

void CBreakEven::ListaBreakTrigger(string pBeArray, double &pArray[]){
  string sBeFaixas[];
  
  ArrayFree(sBeFaixas);
  ArrayFree(pArray);
      
  StringSplit(pBeArray,';',sBeFaixas);
  
  if(ArraySize(sBeFaixas)==0){
    ArrayFree(sBeFaixas);
    ArrayFree(pArray);
  } 
  if(ArraySize(sBeFaixas)==1){
    ArrayResize(pArray, 1);
    pArray[0] = (double)sBeFaixas[0];
  }
  else{
    for(int i=0;i<ArraySize(sBeFaixas);i++){
      ArrayResize(pArray, ArraySize(sBeFaixas));
      pArray[i] = (double)sBeFaixas[i];
    }
  }   
}

void CBreakEven::OnTickEvent(const MqlTick &pTick, ulong pPos, int &pFaixa){
  BreakEven(pTick.last,pPos, pFaixa);
   
}

void CBreakEven::AtualizaFaixas(){
  ListaBreakTrigger(beLtsTrigger,BreakTriggerFaixas);
  ListaBreakTrigger(beLtsStopLoss,BreakStopsFaixas);
  
  int trgFaixa = ArraySize(BreakTriggerFaixas);
  int stpFaixa = ArraySize(BreakStopsFaixas);
  
  if(trgFaixa != stpFaixa){
    Print("Divergência da quantidade faixa entre Trigger e Stop faixa!");
  }
}