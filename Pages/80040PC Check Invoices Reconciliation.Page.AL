page 80040 "PC Check Inv Reconciliations"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "PC Shopify Order Header";
    SourceTableTemporary = true;
    Editable = false;
    Caption = 'Check Invoice Reconcilliation';
    
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("BC Reference No.";rec."BC Reference No.")
                {
                    ApplicationArea = All;
                }
                field("Shopify Order No.";rec."Shopify Order No.")
                {
                    ApplicationArea = All;
                }
                Field("Store Credit Total";rec."Store Credit Total")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice total';
                }
                field("Gift Card Total";rec."Gift Card Total")
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Total';
                }
                field("Freight Total";rec."Freight Total")
                {
                    ApplicationArea = All;
                    Caption = 'Difference';
                    trigger OnDrillDown()
                    var
                        CU:Codeunit "PC Shopify Routines";
                        Buff:Record "PC Shopify Order Header";
                    begin
                        If Rec."Invoice Applied Status" = Rec."Invoice Applied Status"::UnApplied then
                        begin
                            If Confirm('Do you wish to make a Credit Correction Now?',false) then
                            begin
                                Cu.Credit_Correction(Rec."Shopify Order ID"); 
                                Buff.Reset;
                                Buff.Setrange("Shopify Order ID",Rec."Shopify Order ID");
                                If Buff.Findset then
                                begin
                                    Rec."BC Reference No." := Buff."BC Reference No.";
                                    Rec."Store Credit Total" := Rec."Gift Card Total";
                                    Clear(Rec."Freight Total");
                                    Rec.Modify
                                end;
                                currpage.update(false);             
                            end;
                        end
                        else
                            Message('Credit Correction Not Possible .. Invoice has been applied');
                    end;            
                }
            }
            Group(Totals)
            {
                field("Total Difference";Total)
                {
                    ApplicationArea = All;
                    Caption = 'Total Difference';
                    Style = Strong;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Calculate();
    end;
    local procedure Calculate()
    var
        Buff:Record "PC Shopify Order Header";
        SinvLine:array[2] of record "Sales Invoice Line";
        ScrdNote:Record "Sales Cr.Memo Line";
        SinvHdr:Record "Sales Invoice Header";
        ScrdHdr:record "Sales Cr.Memo Header";
        Id:BigInteger;
        win:Dialog;
        j:Decimal;
        CrdCnt:integer;
    Begin
        Clear(Total);
        Rec.reset;
        If Rec.findset then Rec.DeleteAll();
        Win.Open('Processing Invoices @1@@@@@@@@@@@@@@@@');
        SinvHdr.reset;
        //SinvHdr.Setrange("No.",'INV-00000125');
        If SinvHdr.findset then
        repeat
            j += 10000/SinvHdr.count;
            win.update(1,j Div 1);
            Clear(ID);
            SinvLine[1].Reset;
            SinvLine[1].SetCurrentKey("Shopify Order ID");
            SinvLine[1].Setrange("Document No.",SinvHdr."No.");
            If Sinvline[1].Findset  then
            repeat
                If ID <> SinvLine[1]."Shopify Order ID" then
                begin
                    ID := SinvLine[1]."Shopify Order ID";
                    SinvLine[2].reset;
                    SinvLine[2].SetRange("Document No.",SinvLine[1]."Document No.");    
                    Sinvline[2].Setrange("Shopify Order ID",ID);
                    Sinvline[2].Findset;
                    SinvLine[2].CalcSums("Line Amount");
                    Buff.get(ID);
                    If Buff."Shopify Order ID" > 0 then
                    begin
                        If Not Rec.get(ID) then
                        begin
                            Rec.init;
                            Rec."Shopify Order ID" := ID;
                            Rec."BC Reference No." := Buff."BC Reference No.";
                            rec."Shopify Order No." := Buff."Shopify Order No.";
                            Rec."Gift Card Total" := Buff."Order Total";
                            Rec."Invoice Applied Status" := Buff."Invoice Applied Status";
                            Rec.Insert();
                        end;
                        Rec."Store Credit Total" += SinvLine[2]."Line Amount";
                        ScrdHdr.reset;
                        ScrdHdr.Setrange("External Document No.",SinvHdr."No.");
                        If ScrdHdr.findset then
                        begin 
                            ScrdNote.reset;
                            ScrdNote.Setrange("Document No.",ScrdHdr."No.");           
                            ScrdNote.Setrange("Shopify Order ID",ID);
                            If ScrdNote.Findset then
                            begin
                                ScrdNote.CalcSums("Line Amount");
                                rec."Store Credit Total" -= ScrdNote."Line Amount";
                            end;
                        end;        
                        Rec."Freight Total" := Rec."Store Credit Total" - Rec."Gift Card Total";
                        Rec.MOdify;
                    end;
                end;    
            until SinvLine[1].Next = 0;
        Until SinvHdr.next = 0;
        Rec.reset;
        Rec.Findset;
        Rec.CalcSums("Freight Total");
        Total := Rec."Freight Total";        
        win.close;    
        CurrPage.update(false);
    End;

    Var
        InvNo:Code[20];
        Total:Decimal;
}