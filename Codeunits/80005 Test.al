codeunit 80005 Test
{
     Permissions = TableData "Sales Invoice Line" = rm,tabledata "Sales Cr.Memo Line" = rm;
     
var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        WsError:text;
        ShopifyBase:Label '/admin/api/2021-10/';
    trigger OnRun()
    Begin
        Error('This is a test for Vic');
    End;

    procedure Fix_con();
    var
        Recon:array[2] of record "PC Order Reconciliations";
        Cnt:Integer;
    begin
        Clear(Cnt);
        Recon[1].Reset;
        Recon[1].Setrange("shopify Order type",Recon[1]."Shopify Order Type"::Cancelled);
        If Recon[1].Findset then
        repeat
            Recon[2].Reset;
            Recon[2].SetRange("Shopify Order ID",Recon[1]."Shopify Order ID");
            Recon[2].Setrange("Shopify order Type",Recon[1]."Shopify Order Type"::Invoice);
            If Recon[2].Findset then
            begin
                If Recon[2]."Apply Status" <> Recon[1]."Apply Status" then
                begin
                    Recon[1]."Apply Status" := Recon[2]."Apply Status";
                    Recon[1].Modify(False);
                end;
                Recon[2].Delete;
                Cnt+=1;
            end;                       
        until Recon[1].next = 0;
        Message('%1 Records Fixed',Cnt);
    end; 
    Procedure Fix_Shopify_Dates()
    var
        OrhHdr:Record "PC Shopify Order Header";
        SinvLine:record "Sales Invoice Line";
        ScrdLine:record "Sales Cr.Memo Line";
        win:dialog;
        J:decimal;
    begin
        Clear(J);
        Win.Open('Processing Invoices @1@@@@@@@@@@@@@@@@@@');
        OrhHdr.Reset();
        OrhHdr.Setfilter("Order Type",'%1|%2',OrhHdr."Order Type"::Invoice,OrhHdr."Order Type"::Cancelled);
        OrhHdr.Setrange("Order Status",OrhHdr."Order Status"::Closed);
        IF OrhHdr.findset then
        repeat
            j+= 10000/OrhHdr.Count;
            win.update(1,J DIV 1);
            SinvLine.Reset;
            SinvLine.Setrange("Shopify Order ID",OrhHdr."Shopify Order ID");
            If SinvLine.findset then
                SinvLine.ModifyAll("Shopify Order Date",OrhHdr."Shopify Order Date",False);
        until OrhHdr.next = 0;
        Commit;     
        Win.Close;
        Clear(j);   
        Win.Open('Processing Refund @1@@@@@@@@@@@@@@@@@@');
        OrhHdr.Reset();
        OrhHdr.Setrange("Order Type",OrhHdr."Order Type"::CreditMemo);
        OrhHdr.Setrange("Order Status",OrhHdr."Order Status"::Closed);
        IF OrhHdr.findset then
        repeat
            j+= 10000/OrhHdr.Count;
            win.update(1,J DIV 1);
            ScrdLine.Reset;
            SCrdLine.Setrange("Shopify Order ID",OrhHdr."Shopify Order ID");
            If SCrdLine.findset then
                SCrdLine.ModifyAll("Shopify Order Date",OrhHdr."Shopify Order Date",False);
        until OrhHdr.next = 0;
        Win.Close;
        Commit;        
    end;
    procedure Testrun()
    var
        Recon:Record "PC Order Reconciliations";
        GLedg:Record "G/L Entry";
        GenJrnl:Record "Gen. Journal Line";
        GenTemplate:Record "Gen. Journal Template";
        NoSeriesMgt:Codeunit NoSeriesManagement;
        DummyCode:Code[10];
        GLSetup:Record "General Ledger Setup";
        Setup:record "Sales & Receivables Setup";
        LineNo:Integer;
        ClearAcc:Code[20];
        Win:Dialog;
        TmpRecon:Record "PC Order Reconciliations" temporary;
        Cu:Codeunit "Gen. Jnl.-Post";
        PstDate:array[2] of date;
        Dates:array[2] of Date;
    begin
        win.Open('Retrieving Order No #1############'
               + 'Processing Order No #2###########');
        GLSetup.Get;
        Setup.get;
        If (Setup."Debug Start Date" = 0D) Or (Setup."Debug End Date" = 0D) then exit;
        If Setup."Debug Start Date" > Setup."Debug End Date" then exit;
        Clear(PstDate);
        If (GLSetup."Allow Posting To" <> 0D) Or(GLSetup."Allow Posting From" <> 0D) then 
        begin
            PstDate[1] := GLSetup."Allow Posting To";
            PstDate[2] := GLSetup."Allow Posting From";
            Clear(GLSetup."Allow Posting To");
            Clear(GLSetup."Allow Posting From");
            GLSetup.MOdify(false);       
        end;
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then GenJrnl.DeleteAll();
        Clear(LineNo);
        Evaluate(Dates[1],'01/06/2022');
        Evaluate(Dates[2],'05/06/2022');
        Recon.Reset;
        Recon.SetRange("Apply Status",Recon."Apply Status"::UnApplied);
        //Recon.Setrange("Shopify Order No",);
        Recon.Setrange("Shopify Order Date",Setup."Debug Start Date",Setup."Debug End Date");
        If Recon.Findset then
        repeat
            win.update(1,Recon."Shopify Order No");
            GLedg.reset;
            GLedg.Setrange("G/L Account No.",'111130');
            GLedg.Setrange("Bal. Account Type",GLedg."Bal. Account Type"::"G/L Account");
            If Recon."Shopify Order Type" In [Recon."Shopify Order Type"::Invoice,Recon."Shopify Order Type"::Cancelled] then
            begin
                GLedg.Setrange("Document Type",GLedg."Document Type"::Payment);
                GLedg.Setrange(Amount,-Recon."Order Total");
            end    
            else
            begin
                GLedg.Setrange("Document Type",GLedg."Document Type"::refund);
                GLedg.Setrange(Amount,Recon."Order Total");
            end;
            GLedg.Setfilter(Description,'*' + Format(Recon."Shopify Order No") + '*');
            If GLedg.findset then
            begin
                win.update(2,Recon."Shopify Order No");
                Clear(ClearAcc);
                Case ReCon."Payment Gate Way" of
                    ReCon."Payment Gate Way"::"Shopify Pay": ClearAcc := GLSetup."Shopify Pay Clearing Acc"; 
                    ReCon."Payment Gate Way"::Paypal: ClearAcc := GLSetup."PayPal Clearing Acc"; 
                    ReCon."Payment Gate Way"::AfterPay :ClearAcc := GLSetup."AfterPay Clearing Acc"; 
                    ReCon."Payment Gate Way"::Zip:ClearAcc := GLSetup."Zip Clearing Acc"; 
                    ReCon."Payment Gate Way"::MarketPlace: ClearAcc := GLSetup."MarketPlace Clearing Acc"; 
                    ReCon."Payment Gate Way"::Misc: ClearAcc := GLSetup."Misc Clearing Acc";
                end;     
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",Today);
                NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                GenJrnl.VALIDATE("Account Type",GenJrnl."Account Type"::"G/L Account");
                GenJrnl.VALIDATE("Account No.",ClearAcc);
                GenJrnl.Validate("Bal. Account Type",GenJrnl."Bal. Account Type"::"G/L Account");
                GenJrnl.Validate("Bal. Account No.",GLedg."G/L Account No.");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2',Recon."Shopify Order No",Recon."Shopify Order Date");
                If Recon."Shopify Order Type" in [Recon."Shopify Order Type"::Invoice,Recon."Shopify Order Type"::Cancelled] then
                begin
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                    GenJrnl.Validate(Amount,-Recon."Order Total");
                end    
                else
                begin
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                    GenJrnl.Validate(Amount,Recon."Order Total");
                end;    
                GenJrnl.Modify();
                If Not TmpRecon.Get(Recon."Shopify Order ID",Recon."Shopify Order Type") then
                begin
                    TmpRecon.copy(Recon);
                    TmpRecon.Insert(false);
                end;
           end;    
        Until Recon.next = 0;
        Commit;
        win.close;
        Clear(Lineno);
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then 
        Begin
            if Cu.Run(GenJrnl) then
            begin
                TmpRecon.Reset;
                If TmpRecon.Findset then
                repeat
                    If Recon.get(Tmprecon."Shopify Order ID",Tmprecon."Shopify Order Type") then
                    begin
                        Lineno += 1;
                        Recon."Apply Status" := Recon."Apply Status"::CashApplied;
                        Recon.Modify(false);
                    end;
                until TmpRecon.next = 0;
                Message('%1 Entries have been Applied Successfully',Lineno);    
            end
            Else
               Message(GetLastErrorText());    
        end;
        If (PstDate[1] <> 0D) or (PstDate[2] <> 0D)  then
        begin
            GLSetup."Allow Posting To" := PstDate[1];
            GLSetup."Allow Posting From" := PstDate[2];
            GLSetup.Modify(false);
        end;
    end;
}