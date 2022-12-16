page 80046 "PC Refund Checks"
{
    Caption = 'Refund Checks';
    PageType = Card;
  //  SourceTable = "PC Shopify Order Header";
  //  SourceTableView = Where("Order Type"=const(Invoice));
    PromotedActionCategoriesML = ENU = 'Pet Culture',
                                 ENA = 'Pet Culture';

    layout
    {
        area(content)
        {
            group(Refunds)
            {
               field("Shopify Order No";OrdNo)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        OrdHdr:record "PC Shopify Order Header";
                    begin
                        If OrdNo <> 0 then
                        begin
                            OrdHdr.Reset;
                            OrdHdr.Setrange("Shopify Order No.",OrdNo);
                            If Not OrdHdr.Findset then
                            begin
                                Message('Order No %1 does not exist',OrdNo);
                                Clear(OrdNo);
                            end;
                        end;
                    end;       
                }
            }    
            grid(Process)
            {
                field("R";'Initial Refund Check')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown() 
                    var
                        Cu:Codeunit "PC Shopify Routines";
                        Flg:Boolean;
                    begin
                        Flg := Confirm(strsubstno('Perform Initial Refund Check Using Shopify Order No %1 Now',OrdNo),True);
                        If Flg then
                        begin
                            If OrdNo = 0 Then 
                                Flg := Confirm('Order No = 0 Means this can take a long time do you wish to continue',False);
                            If Flg then Cu.Process_Refunds(OrdNo);
                        end;
                    end;    
                }
                field("R1";'Post Refund Check')
                {
                    ApplicationArea = All;
                    ShowCaption = False;
                    Style = StrongAccent;
                    trigger OnDrillDown() 
                    var
                        Cu:Codeunit "PC Shopify Routines";
                        Flg:Boolean;
                    begin
                        Flg := Confirm(strsubstno('Perform Post Refund Check Using Shopify Order No %1 Now',OrdNo),True);
                        If Flg then
                        begin
                            If OrdNo = 0 Then Flg := Confirm('Order No = 0 Means this can take a long time do you wish to continue',False);
                            If Flg then Cu.Check_For_Extra_Refunds(OrdNo);
                        end;
                    end;    
                }
            }
        }
    }
    Var 
        OrdNo:BigInteger;


}
