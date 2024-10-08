/*
  BotTrade.mqh
  CopyRight 2024, Sidjeanp
  https://www.sidjeanp.com
*/
#property copyright "CopyRight 2024, Sidjeanp"
#property link      "https://www.sidjeanp.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Sidjeanp/Bot/Utils.mqh>
#include <Sidjeanp/Bot/MediaMoving.mqh>
#include <Sidjeanp/Bot/ControlerTrade.mqh>
#include <Sidjeanp/Bot/BreakEven.mqh>
#include <Sidjeanp/Bot/CrossMediaMoving.mqh>

class CBotTrade : public CControlerTrade {
private:   
   
   int mediaPeriodo1;
   ENUM_MA_METHOD ma_metodo1;
   ENUM_APPLIED_PRICE ma_preco1;
   
   int mediaPeriodo2;
   ENUM_MA_METHOD ma_metodo2;
   ENUM_APPLIED_PRICE ma_preco2;
   
   int mediaPeriodo3;
   ENUM_MA_METHOD ma_metodo3;
   ENUM_APPLIED_PRICE ma_preco3;
   
   ENUM_ORDER_TYPE_FILLING preenchimento;
   

///   ENUM_TIMEFRAMES period;
   
///   double lote;
   double stopLoss;
   double takeProfit;
   double zonaNotOpe;
   ulong desvPts;
   double spredMax;
   
   bool   bHabCompas;
   bool   bHabVendas;
   int    operacaoPorCandle;
   
   double trlTrigger;
   double trlStopLoss;
   double stepTS;
   
   string opDias;
   string opHorario;
   string opDiasHorarios;
   /////
   
   MqlRates rates[];
   
   CMediaMoving mediaMov;
   CCrossMediaMoving crossMedia;
   
   double mediaArray1[];
   double mediaArray2[];
   double mediaArray3[];
   
   int mediaHandle1;
   int mediaHandle2;
   int mediaHandle3;
   
   ENUM_TO_OPERATION_TYPE statusMedias;
   ENUM_TO_OPERATION_TYPE reverseMedias;
   
   bool posAberta;
   bool ordPendente;
   bool beAtivo;
   bool orientacaoOpBuy;
   bool operInZone;
   bool operar;
   double spread;
   
   ENUM_TO_OPERATION_TYPE buySell;
   
   double PRC; //
   double BD;
   double STL;
   double TKP;
   
   string diasParaOperacao[];
   
   MDiasHoras horasParaOperacao[];
   
   datetime lastCandleTime;
   datetime currentCandleTime;
   
   
   int tempoEntreOperacoes;
   
   CBreakEven* oBreakEven;
   CCrossMediaMoving* oCrossMedia;
   
protected:
   void DefineQtdOpeCandle();
   void OperarNegociacao();
  
public:
   void Init();
   void CriarNovaMediaMovel();
   
   CBotTrade(MParam &param);
   CBotTrade();
  ~CBotTrade();
   
   void CriaMediasMoveis();

   void AtualizaArrays();
   
   void OnTickEvent() override; 
   
   void DefineOperacao(ENUM_TO_OPERATION_TYPE &pBuySell, bool &pOperar, bool &poperInZone);
   void ValidarPosicoesAposCruzamento(MPositions &listaPos[],ENUM_TO_OPERATION_TYPE tipoOperacao);
   
   void TraillingStop(double preco);
   
   bool PermiteOperar(ENUM_TO_OPERATION_TYPE pBuySell);
   
   void CarregaPositions();
   

};

CBotTrade::CBotTrade(MParam &param) {
    if (StringLen(param.pSymbol) == 0) {
        symbol = _Symbol;
    } else {
        symbol = param.pSymbol;
    }

    if (StringLen(param.pPeriod) == 0) {
        period = _Period;
    } else {
        period = param.pPeriod;
    }

    lote = param.pLote;
    stopLoss = param.pStopLoss;
    takeProfit = param.pTakeProfit;
    zonaNotOpe = param.pZonaNotOpe;
    magicNum = param.pMagicNum;
    desvPts = param.pDesvPts;
    spredMax = param.pSpredMax;
    
    operacaoPorCandle = param.pOperacaoPorCandle;
    
    ArrayResize(listaPositions, 0);

    operar = false;
    buySell = UNDEF;
    Print("Carregou parametros");
    DefineQtdOpeCandle();
    Print("Qtd por candles");
    
    Print("Carregando as Médias Moveis");
    CriaMediasMoveis();
    Print("Médias Moveis concluído");
    
    TrataDiasParaOperar(opDias, diasParaOperacao);
    TrataHorarioParaOperar(opHorario, opDiasHorarios, horasParaOperacao);
    TrataDiasHorariosParaOperar(opDiasHorarios,horasParaOperacao);  
    
    trade.SetTypeFilling(preenchimento);
    trade.SetDeviationInPoints(desvPts);
    trade.SetExpertMagicNumber(magicNum);
    
    oBreakEven = new CBreakEven(trade,param.pBreakEven);  
    oCrossMedia = new CCrossMediaMoving(param.pLtsCrossMediaMovel);  
    
    operInZone = false;   
}


CBotTrade::CBotTrade(){
}

void CBotTrade::DefineQtdOpeCandle(){
  tempoEntreOperacoes = PeriodSeconds() / operacaoPorCandle;
}

void CBotTrade::CriaMediasMoveis(){
  mediaMov   = new CMediaMoving();
  
  
  MMediaMov paramMedia;
  paramMedia.symbol = symbol; // Símbolo atual
  paramMedia.period = period; // Período M15
  paramMedia.mediaPeriodo = 7; // Período da média móvel
  paramMedia.ma_metodo = MODE_EMA; // Método de média: Exponencial
  paramMedia.ma_preco = PRICE_CLOSE; // Tipo de preço: preço de fechamento
  paramMedia.lineColor = clrViolet;
  mediaMov.AddMedia(paramMedia);
  //mediaMov.add(clrViolet, "moving_averages");
  
  
  MMediaMov paramMedia2;
  paramMedia2.symbol = symbol; // Símbolo atual
  paramMedia2.period = period; // Período M15
  paramMedia2.mediaPeriodo = 89; // Período da média móvel
  paramMedia2.ma_metodo = MODE_EMA; // Método de média: Exponencial
  paramMedia2.ma_preco = PRICE_CLOSE; // Tipo de preço: preço de fechamento  
  paramMedia2.lineColor = clrBlueViolet;
  
  mediaMov.AddMedia(paramMedia2);
  //mediaMov.CriarNovaMediaMovel(clrBlueViolet, "moving_averages");
  
}

CBotTrade::~CBotTrade(){
  delete oBreakEven; 
  delete oCrossMedia; 
}


void CBotTrade::AtualizaArrays(){
  mediaMov.AtualizaMedias();
}

void CBotTrade::OnTickEvent(){
  
  Print("Carrega arrays");
  AtualizaArrays();
  Print("Carregado arrays");
  
  oCrossMedia.OnTickEvent();
  
  buySell = oCrossMedia.GetBuySell();
  operar = oCrossMedia.GetOperar();
  //operInZone = oCrossMedia.GetOperar();
  //DefineOperacao(buySell, operar, operInZone);
  
  statusMedias = oCrossMedia.GetStatusMedias();
 
  //CheckStatusMedias(statusMedias, mediaMov.ListaIma[0].mediaArray, mediaMov.ListaIma[1].mediaArray, zonaNotOpe );
  
  CControlerTrade::OnTickEvent();//herança
  
  reverseMedias = MediaReversa(statusMedias);
  
  if(ArraySize(listaPositions)>0){
    if(TemPosition(listaPositions,reverseMedias,symbol,magicNum)){  
      ValidarPosicoesAposCruzamento(listaPositions,statusMedias); 
    }
  }
  
  posAberta = ArraySize(listaPositions)>0;

  if(!posAberta){
    beAtivo = false;    
  }    
  /*
  if(posAberta && beTrigger > 0){
    BreakEven(ultimoTick.last);
  }*/
  
  for(int i = 0; i < ArraySize(listaPositions); i++){
    oBreakEven.OnTickEvent(ultimoTick,listaPositions[i].position, listaPositions[i].pFaixa);
  }
  
  
  if(posAberta && trlTrigger > 0){
    TraillingStop(ultimoTick.last);
  }
  
  if(PermiteOperar(buySell) && (operar || !posAberta) 
     && (!TemPosition(listaPositions,statusMedias,symbol,magicNum))
     && (!TemOrder(listaOrders,statusMedias,symbol,magicNum))){
    OperarNegociacao();
  }
     
}


void CBotTrade::ValidarPosicoesAposCruzamento(MPositions &listaPos[],ENUM_TO_OPERATION_TYPE tipoOperacao) {
  for (int i = ArraySize(listaPos) - 1; i >= 0; i--) {
    ulong positionTicket = listaPos[i].position;
    if (!PositionSelectByTicket(positionTicket)) {
       Print("Falha ao selecionar o ticket");
    } 
    else {
      ENUM_POSITION_TYPE tipoPosicao = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if ((tipoOperacao == TO_BUY) && (tipoPosicao != POSITION_TYPE_BUY)) {
       // Se a posição não é mais uma posição de compra, feche-a
       Print("Fecha compra em posição de venda - validarPosicoes");
       FecharOperacao(positionTicket);
       ArrayRemove(listaPos, i);      
      }
      else if ((tipoOperacao == TO_SELL) && (tipoPosicao != POSITION_TYPE_SELL)) {
        // Se a posição não é mais uma posição de venda, feche-a
        Print("Fecha venda em posição de compra - validarPosicoes");
        FecharOperacao(positionTicket);
        ArrayRemove(listaPos, i);                 
      }
    }
  }
}

void CBotTrade::OperarNegociacao(){
  bool abriuNovaOrdem = false; 
     
  double buyAskLoss = 0;
  double buyAskProfit = 0;
  double sellAskLoss = 0;
  double sellAskProfit = 0;
  double buyAsk = 0;
  double sellAsk = 0;
 
  PRC = ultimoTick.ask;
  BD = ultimoTick.bid;
  STL = NormalizeDouble(ultimoTick.ask,_Digits);
  TKP = NormalizeDouble(ultimoTick.ask,_Digits);    
 
  if(stopLoss != 0.0){
    buyAskLoss = NormalizeDouble(ultimoTick.ask-(stopLoss*_Point),_Digits);
    sellAskLoss = NormalizeDouble(ultimoTick.bid+(stopLoss*_Point),_Digits);
  }
  if(takeProfit != 0.0){
    buyAskProfit = NormalizeDouble(ultimoTick.ask+(takeProfit*_Point),_Digits);
    sellAskProfit = NormalizeDouble(ultimoTick.bid-(takeProfit*_Point),_Digits);
  }

  buyAsk = PRC;
  sellAsk = BD;
 
  MPositions listaHistorico[];
  datetime horaUltCancles = iTime(symbol, period, 0);
  
  ListarHistoricoPosicoes(listaHistorico,horaUltCancles, symbol,period,magicNum,tempoAtual);
  bool permiteNovaOperacao = PermitePositionMesmoCandle(listaHistorico,tempoAtual,operacaoPorCandle,tempoEntreOperacoes);
  
  if(permiteNovaOperacao){
    if(buySell == 0){
      if(OperarCompra("Bot Compra")){
        Print("Ordem de compra padrão sem falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
        operInZone = false;
        abriuNovaOrdem = true;
      }
      else{
        Print("Ordem de compra padrão com falha. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
      }
    }
    else if(buySell == 1){
      if(OperarVenda("Bot Venda")){
        Print("Ordem de venda padrão sem falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
        operInZone = false;
        abriuNovaOrdem = true;
      }
      else{
        Print("Ordem de venda padrão com falha.. ResultRetCode: ",trade.ResultRetcode()," RetCodeDescription: ", trade.ResultRetcodeDescription());
      }    
    }
  }
}


void CBotTrade::TraillingStop(double preco){
  if(trlTrigger>0){
     double stopLossCorrente = 0;
     double takeProfitCorrente = 0;
     double precoEntrada = 0;
     double trlStop = 0;
       
     for(int i = PositionsTotal()-1; i>=0; i--){
       string symbol = PositionGetSymbol(i);
       ulong magic = PositionGetInteger(POSITION_MAGIC);
       
       if(symbol==symbol){
         ulong positionTicket = PositionGetTicket(i);
         if(!PositionSelectByTicket(positionTicket)){
           Print("Falha ao selecionar o ticket");
         }
        
         precoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
         stopLossCorrente = PositionGetDouble(POSITION_SL);
         takeProfitCorrente = PositionGetDouble(POSITION_TP);
         trlStop = 0;   
         Print("Pegou stopLossCorrente: ",stopLossCorrente," precoEntrada: ",precoEntrada);
         ///Alert("Até aqui antes de alterar entrou sem problemas",preco);
         
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ 
           ///Print("TraillingStop - Compra",preco," | ",precoEntrada," | ",(trlTrigger*_Point));
           if((trlStopLoss > 0) &&(preco >= (precoEntrada + (trlTrigger*_Point)))){
             Alert("TraillingStop - Atingiu preço trigger: ",(preco - (stopLossCorrente)), " | ",(trlStopLoss+stepTS)*_Point);
             if((preco - (stopLossCorrente)) > (((trlStopLoss+stepTS)*_Point)) ){
               trlStop = preco-(trlStopLoss*_Point);          
                     
               double novoSL = NormalizeDouble(trlStop,_Digits);
   
               if(trade.PositionModify(positionTicket,novoSL,takeProfitCorrente)){
                 Print("TraillingStop - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
               }
               else{
                 Print("TraillingStop - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
               }
             }          
           } 
         }
         else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
           if(preco < (precoEntrada - (trlTrigger*_Point))){
   
             Print(" stopLossCorrente: ",(stopLossCorrente),
                   " trlStopLoss1: ", (preco+(trlStopLoss*_Point)), 
                   " trlStopLoss2: ", (preco-(trlStopLoss*_Point)), 
                   " trlStopLoss3: ", ((trlStopLoss*_Point)),
                   " Preço: ",preco);
             Print(" precoEntrada: ",(precoEntrada),
                   " trlStopLoss1: ", (precoEntrada+(trlStopLoss*_Point)), 
                   " trlStopLoss2: ", (precoEntrada-(trlStopLoss*_Point)), 
                   " trlStopLoss3: ", ((trlStopLoss*_Point)),
                   " Preço: ",preco);  
             Print("trlStopLoss: ", trlStopLoss, " IF1: ",(stopLossCorrente-preco), "IF2: ",((stopLossCorrente-preco) < (trlStopLoss*_Point)));
             if((trlStopLoss>0) && (((stopLossCorrente-preco) > (trlStopLoss*_Point)) || stopLossCorrente==0 )){
               trlStop = preco+(trlStopLoss*_Point); 
               Print("Novo stop: ", trlStop);            
                       
               double novoSL = trlStop;
               ///Alert("Modifica operação - TraillingStop: else");
               if(trade.PositionModify(positionTicket,novoSL,takeProfitCorrente)){
                 Print("TraillingStop - Sem falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
               }
               else{
                 Print("TraillingStop - Com falha. ResultRetcode: ",trade.ResultRetcode(),", RecodeDescription: ", trade.ResultRetcodeDescription());
               }                  
             }
           }       
         }     
       }  
     }
  }
}

bool CBotTrade::PermiteOperar(ENUM_TO_OPERATION_TYPE pBuySell){
  //--- Valida dias da semana  
  bool retorna = true;
  int diaDaSemana = DateTimeStructure.day_of_week;  
  bool opValHora = false;
  bool opValToDay = false;
  
  if(buySell==TO_BUY){
    Print("Permite Compra?");
  }
  else if(buySell==TO_SELL){
    Print("Permite Venda?");
  }
  else{
    Print("PErmite Sem definição");
  }
  
  //--- Valida dia da semana  
  if(horasParaOperacao[0].dia==""){
    opValToDay = ArrayContains(diasParaOperacao, diaDaSemana);
  }
  
  
  //--- Valida range de horário  
  MqlDateTime horaInicio, horaFim;
  
  if(horasParaOperacao[0].dia==""){
    for(int i=0;i<=ArraySize(horasParaOperacao)-1;i++){
      TimeToStruct(StringToTime(horasParaOperacao[i].inicio), horaInicio);
      TimeToStruct(StringToTime(horasParaOperacao[i].fim), horaFim);
    
      if (IsTimeWithinRange(horaInicio, horaFim, DateTimeStructure)) {
        opValHora = true;
        break;    
      }
    }
  }
  else{
  //--- Valida dia e range de horario  
    for(int i=0;i<=ArraySize(horasParaOperacao)-1;i++){
      TimeToStruct(StringToTime(horasParaOperacao[i].inicio), horaInicio);
      TimeToStruct(StringToTime(horasParaOperacao[i].fim), horaFim);
    
      if ((diaDaSemana==horasParaOperacao[i].dia) && (IsTimeWithinRange(horaInicio, horaFim, DateTimeStructure))) {
        opValHora = true;
        opValToDay = true;
        break;    
      }
    }  
  }
  
  //--- Compra e Venda
  bool opBuySeel = false;
  if(bHabCompas==bHabVendas){
    opBuySeel = true;
  }
  else if((pBuySell==TO_BUY) && (bHabCompas)){
    opBuySeel = true;
  }
  else if((pBuySell==TO_SELL) && (bHabVendas)){
    opBuySeel = true;
  }
  
/*  if(opValToDay){
    Comment("Dia da semana operar: ",diaSemana(diaDaSemana));
  }
  else{
    Comment("Dia da semana NÃO operar: ",diaSemana(diaDaSemana));
  }
  
  if(opValHora){
    Comment("Hora opera: ",DateTimeStructure.hour,':',DateTimeStructure.min,':',DateTimeStructure.sec);
  }
  else{
    Comment("Hora NÃO opera: ",DateTimeStructure.hour,':',DateTimeStructure.min,':',DateTimeStructure.sec);
  } */ 
  
  
  ///Alert("Validação ToDay: ",opValToDay, " Hora: ",opValHora," Operação: ", opBuySeel );
  retorna = (opValToDay && opValHora && opBuySeel);
  return retorna; 
  
}


