codeunit 80006 "PC Reconcillations"
{
    procedure Build_Cash_Receipts(var Buff:record "PC Shopify Order Header";PostDate:date)
    var
        GenJrnlBatch:record "Gen. Journal Batch";
        GenJrnl:Record "Gen. Journal Line";
        GenTemplate:Record "Gen. Journal Template";
        NoSeriesMgt:Codeunit NoSeriesManagement;
        DummyCode:Code[10];
        GLSetup:Record "General Ledger Setup"; 
        Lineno:Integer;
        Sinv:Record "Sales Invoice Header";
        Scrd:record "Sales Cr.Memo Header";
        Doc:Code[20];
        InvTot:Decimal;
        CrdTot:decimal;
        GenJtrnTemp:Record "Gen. Journal Template";
        Cu:Codeunit "Gen. Jnl.-Post";
        PstDate:date; 
        TmpBuff:record "PC Shopify Order Header" temporary;
    begin
        TmpBuff.Reset();
        If Tmpbuff.Findset then TmpBuff.DeleteAll();
        GLSetup.get;
        If GLSetup."Reconcillation Bank Acc" = '' then
        begin
            Message('Reconcilliation Bank acc not defined in General Ledger Setup');
            exit;
        end;    
        If GLSetup."Reconcillation Clearing Acc" = '' then
        begin
            Message('Reconcilliation Clearing acc not defined in General Ledger Setup');
            exit;
        end; 
        If Not GenJtrnTemp.Get('CASH RECE') then
        begin
            GenJtrnTemp.Init();
            GenJtrnTemp.Validate(Name,'CASH RECE');
            GenJtrnTemp.insert;
            GenJtrnTemp.Description := 'Cash Receipts journal';
            GenJtrnTemp.validate(Type,GenJtrnTemp.type::"Cash Receipts");
            GenJtrnTemp.Validate("Bal. Account Type",GenJtrnTemp."Bal. Account Type"::"G/L Account");
            GenJtrnTemp.Validate("Source Code",'CASHRECJNL');
            GenJtrnTemp.Validate("Force Doc. Balance",true);
            GenJtrnTemp.Validate("Copy VAT Setup to Jnl. Lines",true);
            GenJtrnTemp.validate("Copy to Posted Jnl. Lines",true);
            GenJtrnTemp.Modify();
        end;
        If Not GenJrnlBatch.Get('CASH RECE','DEFAULT') then
        begin
            GenJrnlBatch.init;
            GenJrnlBatch.validate("Journal Template Name",'CASH RECE');
            GenJrnlBatch.Validate(Name,'DEFAULT');
            GenJrnlBatch.Insert();
            GenJrnlBatch.Validate("Bal. Account Type",GenJrnlBatch."Bal. Account Type"::"G/L Account");
            GenJrnlBatch.Validate("No. Series",'GJNL-RCPT');
            GenJrnlBatch.modify();
        end;
        Clear(PstDate);
        If (GLSetup."Allow Posting To" <> 0D) AND (GLSetup."Allow Posting To" < Today) then 
        begin
            PstDate := GLSetup."Allow Posting To";
            Clear(GLSetup."Allow Posting To");
            GLSetup.MOdify(false);       
        end;
        Clear(InvTot);
        Clear(CrdTot);
        Clear(Lineno);
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then GenJrnl.DeleteAll();
        Buff.Setrange("Cash Receipt Status",Buff."Cash Receipt Status"::UnApplied);
        Buff.Setfilter(Buff."Order Total",'>0');
        If Buff.findset then
        repeat
            If Buff."Order Type" = Buff."Order Type"::Invoice then
                InvTot += Buff."Order Total"
            else
                CrdTot -= Buff."Order Total";
        until Buff.next = 0;
        if InvTot > 0 then
        begin
            GenJrnl.INIT;
            GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
            GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
            GenJrnl."Source Code" := 'CASHRECJNL';
            LineNo += 10;
            GenJrnl."Line No." := LineNo;
            GenJrnl.INSERT(true);
            GenJrnl.FILTERGROUP(2);
            GenJrnl.VALIDATE("Posting Date",PostDate);
            NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
            Doc := GenJrnl."Document No.";
            GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"Bank Account");
            GenJrnl.Validate("Account No.",GLSetup."Reconcillation Bank Acc");
            GenJrnl.Description := StrSubstNo('%1 Payments For %2',Buff."Payment Gate Way",Today);
            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
            GenJrnl.Validate(Amount,InvTot);
            GenJrnl.Modify();
            Buff.Setrange("Order Type",Buff."Order Type"::Invoice);
            If Buff.findset then
            repeat
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",PostDate);
                GenJrnl."Document No." := Doc;
                GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                GenJrnl.Validate("Account No.",GLsetup."Reconcillation Clearing Acc");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2 - ' + Buff."Payment Gate Way", Buff."Shopify Order No.",Buff."Shopify Order Date");
                GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                GenJrnl.Validate(Amount,-Buff."Order Total");
                GenJrnl.Modify();
                Buff."Cash Receipt Status" := Buff."Cash Receipt Status"::Applied;
                Buff.Modify();
                TmpBuff.Copy(Buff);
                TmpBuff.insert;
            until Buff.next = 0;
            Commit;
        end;
        if CrdTot < 0 then
        begin
            GenJrnl.INIT;
            GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
            GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
            GenJrnl."Source Code" := 'CASHRECJNL';
            LineNo += 10;
            GenJrnl."Line No." := LineNo;
            GenJrnl.INSERT(true);
            GenJrnl.FILTERGROUP(2);
            GenJrnl.VALIDATE("Posting Date",PostDate);
            NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
            Doc := GenJrnl."Document No.";
            GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"Bank Account");
            GenJrnl.Validate("Account No.",GLSetup."Reconcillation Bank Acc");
            GenJrnl.Description := StrSubstNo('%1 Refunds For %2',Buff."Payment Gate Way",Today);
            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
            GenJrnl.Validate(Amount,CrdTot);
            GenJrnl.Modify();
            Buff.Setrange("Order Type",Buff."Order Type"::CreditMemo);
            If Buff.findset then
            repeat
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",PostDate);
                GenJrnl."Document No." := Doc;
                GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                GenJrnl.Validate("Account No.",GLsetup."Reconcillation Clearing Acc");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2 - ' + Buff."Payment Gate Way", Buff."Shopify Order No.",Buff."Shopify Order Date");
                GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                GenJrnl.Validate(Amount,Buff."Order Total");
                GenJrnl.Modify();
                Buff."Cash Receipt Status" := Buff."Cash Receipt Status"::Applied;
                Buff.Modify();
                TmpBuff.Copy(Buff);
                TmpBuff.insert;
            until Buff.next = 0;
            Commit;
        end;
        Clear(Doc);
        Buff.Setrange("Order Type");
        Buff.Setrange("Cash Receipt Status",Buff."Cash Receipt Status"::Applied);
        Buff.Setrange("Invoice Applied Status",Buff."Invoice Applied Status"::UnApplied);
        Buff.Setfilter("BC Reference No.",'<>%1&<>%2','','N/A');
        Buff.Setfilter(Buff."Order Total",'>0');
        If Buff.findset then
        repeat
            Clear(Doc);
            If Sinv.get(Buff."BC Reference No.") AND (Buff."Order Type" = Buff."Order Type"::Invoice) then
                Doc := Sinv."No."
            else If Scrd.get(Buff."BC Reference No.") AND (Buff."Order Type" = Buff."Order Type"::CreditMemo) then
                     Doc := Scrd."No.";
            If doc <> '' then
            begin
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",PostDate);
                NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                GenJrnl.VALIDATE("Account Type",GenJrnl."Account Type"::Customer);
                GenJrnl.VALIDATE("Account No.",'PETCULTURE');
                GenJrnl.Validate("Bal. Account Type",GenJrnl."Bal. Account Type"::"G/L Account");
                GenJrnl.Validate("Bal. Account No.",GLSetup."Reconcillation Clearing Acc");
                GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2',Buff."Shopify Order No.",Buff."Shopify Order Date");
                If Buff."Order Type" = Buff."Order Type"::Invoice then
                begin
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                    GenJrnl.Validate(Amount,-Buff."Order Total");
                    GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::Invoice;
                end    
                else
                begin
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                    GenJrnl.Validate(Amount,Buff."Order Total");
                    GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::"Credit Memo";
                end;
                GenJrnl."Applies-to Doc. No." := Doc;
                GenJrnl.Modify();
                Buff."Invoice Applied Status" := Buff."Invoice Applied Status"::Applied;
                Buff.Modify();
                TmpBuff.Copy(Buff);
                If TmpBuff.Get(Buff.ID) then
                    TmpBuff.modify
                else
                    Tmpbuff.Insert();    
            end;
        until Buff.next = 0;
        Commit; 
        if Not GenJrnl.IsEmpty then 
        Begin
            if not Cu.Run(GenJrnl) then
            begin
                TmpBuff.Reset;
                TmpBuff.Findset;
                repeat
                    Buff.Get(TmpBuff.ID);
                    Buff."Cash Receipt Status" := Buff."Cash Receipt Status"::UnApplied;
                    Buff."Invoice Applied Status" := Buff."Invoice Applied Status"::UnApplied;
                    Buff.Modify();
                until TmpBuff.next = 0;    
            end;
        end;
        If PstDate <> 0D then
        begin
            GLSetup."Allow Posting To" := PstDate;
            GLSetup.Modify(false);
        end;
    end;   
    procedure Build_Reconcilliation_Cash_Receipts(var Buff:record "PC Order Reconciliations" temporary;FeeAcc:Code[20];PostDate:Date;Fee:Decimal)
    var
        GenJrnlBatch:record "Gen. Journal Batch";
        GenJrnl:Record "Gen. Journal Line";
        GenTemplate:Record "Gen. Journal Template";
        NoSeriesMgt:Codeunit NoSeriesManagement;
        DummyCode:Code[10];
        GLSetup:Record "General Ledger Setup";
        ClearAcc:Code[20];
        Lineno:Integer;
        Sinv:Record "Sales Invoice Header";
        Scrd:record "Sales Cr.Memo Header";
        Doc:Code[20];
        InvTot:Decimal;
        CrdTot:decimal;
        GenJtrnTemp:Record "Gen. Journal Template";
        Cu:Codeunit "Gen. Jnl.-Post";
        PstDate:array[2] of date;
        OrdHdr:Record "PC Shopify Order Header";
        TmpBuff1:record "PC Order Reconciliations" temporary;
        TmpBuff2:record "PC Order Reconciliations" temporary;
        RecCon:Record "PC Order Reconciliations";
        CustLed:record "Cust. Ledger Entry";
        RecTot:Record "PC Reconciliation Totaler" temporary;
        ExFlg:Boolean;
        OrdFlg:boolean;
        i:Integer;
    begin
        TmpBuff1.reset;
        If Tmpbuff1.Findset then Tmpbuff1.DeleteAll();
        TmpBuff2.reset;
        If Tmpbuff2.Findset then Tmpbuff2.DeleteAll();
        GLSetup.get;
        If GLSetup."Reconcillation Bank Acc" = '' then
        begin
            Message('Reconcilliation Bank acc not defined in General Ledger Setup');
            exit;
        end;
        If Not Buff.IsEmpty then
        begin    
            Case Buff."Payment Gate Way" of 
                Buff."Payment Gate Way"::"Shopify Pay":
                begin
                    If GLSetup."Shopify Pay Clearing Acc" = '' then
                    begin
                        Message('Shopify Pay Clearing acc not defined in General Ledger Setup');
                        exit;
                    end;
                    ClearAcc := GLSetup."Shopify Pay Clearing Acc";    
                end;
                Buff."Payment Gate Way"::PayPal:
                begin
                    If GLSetup."PayPal Clearing Acc" = '' then
                    begin
                        Message('PayPal Clearing acc not defined in General Ledger Setup');
                        exit;
                    end;  
                    ClearAcc := GLSetup."PayPal Clearing Acc";    
                end;
                Buff."Payment Gate Way"::AfterPay:
                begin
                    If GLSetup."AfterPay Clearing Acc" = '' then
                    begin
                        Message('After Pay Clearing acc not defined in General Ledger Setup');
                        exit;
                    end;    
                    ClearAcc := GLSetup."AfterPay Clearing Acc";    
                end;
                Buff."Payment Gate Way"::MarketPlace:
                begin
                    If GLSetup."MarketPlace Clearing Acc" = '' then
                    begin
                        Message('MarketPlace Clearing acc not defined in General Ledger Setup');
                        exit;
                    end;    
                    ClearAcc := GLSetup."MarketPlace Clearing Acc";    
                end;
                Buff."Payment Gate Way"::Zip:
                begin
                    If GLSetup."Zip Clearing Acc" = '' then
                    begin
                        Message('Zip Clearing acc not defined in General Ledger Setup');
                        exit;
                    end;    
                    ClearAcc := GLSetup."Zip Clearing Acc";    
                end;
                Buff."Payment Gate Way"::Misc:
                begin
                    If GLSetup."Misc Clearing Acc" = '' then
                    begin
                        Message('Misc Clearing acc not defined in General Ledger Setup');
                        exit;
                    end;    
                    ClearAcc := GLSetup."Misc Clearing Acc";    
                end;
            End;
            If Not GenJtrnTemp.Get('CASH RECE') then
            begin
                GenJtrnTemp.Init();
                GenJtrnTemp.Validate(Name,'CASH RECE');
                GenJtrnTemp.insert;
                GenJtrnTemp.Description := 'Cash Receipts journal';
                GenJtrnTemp.validate(Type,GenJtrnTemp.type::"Cash Receipts");
                GenJtrnTemp.Validate("Bal. Account Type",GenJtrnTemp."Bal. Account Type"::"G/L Account");
                GenJtrnTemp.Validate("Source Code",'CASHRECJNL');
                GenJtrnTemp.Validate("Force Doc. Balance",true);
                GenJtrnTemp.Validate("Copy VAT Setup to Jnl. Lines",true);
                GenJtrnTemp.validate("Copy to Posted Jnl. Lines",true);
                GenJtrnTemp.Modify();
            end;
            If Not GenJrnlBatch.Get('CASH RECE','DEFAULT') then
            begin
                GenJrnlBatch.init;
                GenJrnlBatch.validate("Journal Template Name",'CASH RECE');
                GenJrnlBatch.Validate(Name,'DEFAULT');
                GenJrnlBatch.Insert();
                GenJrnlBatch.Validate("Bal. Account Type",GenJrnlBatch."Bal. Account Type"::"G/L Account");
                GenJrnlBatch.Validate("No. Series",'GJNL-RCPT');
                GenJrnlBatch.modify();
            end;
            Clear(PstDate);
            If (GLSetup."Allow Posting To" <> 0D) Or(GLSetup."Allow Posting From" <> 0D) then 
            begin
                PstDate[1] := GLSetup."Allow Posting To";
                PstDate[2] := GLSetup."Allow Posting From";
                Clear(GLSetup."Allow Posting To");
                Clear(GLSetup."Allow Posting From");
                GLSetup.MOdify(false);       
            end;
            Clear(InvTot);
            Clear(CrdTot);
            Clear(Lineno);
            GenJrnl.reset;
            GenJrnl.Setrange("Journal Template Name",'CASH RECE');
            GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
            If GenJrnl.findset then GenJrnl.DeleteAll();
            Buff.Setrange("Apply Status",Buff."Apply Status"::UnApplied);
            Buff.Setfilter(Buff."Order Total",'>0');
            If Buff.findset then
            repeat
                If Buff."Shopify Order Type" in [Buff."Shopify Order Type"::Invoice,Buff."Shopify Order Type"::Cancelled] then
                    InvTot += Buff."Order Total"
                else
                    CrdTot -= Buff."Order Total";
            until Buff.next = 0;
            if InvTot > 0 then
            begin
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",PostDate);
                NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                Doc := GenJrnl."Document No.";
                GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"Bank Account");
                GenJrnl.Validate("Account No.",GLSetup."Reconcillation Bank Acc");
                GenJrnl.Description := StrSubstNo('%1 Payments For %2',Buff."Payment Gate Way",PostDate);
                GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                GenJrnl.Validate(Amount,InvTot);
                GenJrnl.Modify();
                Buff.SetFilter("Shopify Order Type",'%1|%2',Buff."Shopify Order Type"::Invoice,Buff."Shopify Order Type"::Cancelled);
                If Buff.findset then
                repeat
                    GenJrnl.INIT;
                    GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                    GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                    GenJrnl."Source Code" := 'CASHRECJNL';
                    LineNo += 10;
                    GenJrnl."Line No." := LineNo;
                    GenJrnl.INSERT(true);
                    GenJrnl.FILTERGROUP(2);
                    GenJrnl.VALIDATE("Posting Date",PostDate);
                    GenJrnl."Document No." := Doc;
                    GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                    GenJrnl.Validate("Account No.",ClearAcc);
                    GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2 - ' + Format(Buff."Payment Gate Way"), Buff."Shopify Order No",Buff."Shopify Order Date");
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                    GenJrnl.Validate(Amount,-Buff."Order Total");
                    GenJrnl.Modify();
                    Buff."Apply Status" := Buff."Apply Status"::CashApplied;
                    Buff.Modify();
                    If Not TmpBuff1.Get(Buff."Shopify Order ID",Buff."Shopify Order Type") then
                    begin
                        TmpBuff1.Copy(Buff);
                        TmpBuff1.insert;
                    end;    
                until Buff.next = 0;
                Commit;
            end;
            if CrdTot < 0 then
            begin
                GenJrnl.INIT;
                GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                GenJrnl."Source Code" := 'CASHRECJNL';
                LineNo += 10;
                GenJrnl."Line No." := LineNo;
                GenJrnl.INSERT(true);
                GenJrnl.FILTERGROUP(2);
                GenJrnl.VALIDATE("Posting Date",PostDate);
                NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                Doc := GenJrnl."Document No.";
                GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"Bank Account");
                GenJrnl.Validate("Account No.",GLSetup."Reconcillation Bank Acc");
                GenJrnl.Description := StrSubstNo('%1 Refunds For %2',Buff."Payment Gate Way",PostDate);
                GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                GenJrnl.Validate(Amount,CrdTot);
                GenJrnl.Modify();
                Buff.Setrange("Shopify Order Type",Buff."Shopify Order Type"::Refund);
                If Buff.findset then
                repeat
                    GenJrnl.INIT;
                    GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                    GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                    GenJrnl."Source Code" := 'CASHRECJNL';
                    LineNo += 10;
                    GenJrnl."Line No." := LineNo;
                    GenJrnl.INSERT(true);
                    GenJrnl.FILTERGROUP(2);
                    GenJrnl.VALIDATE("Posting Date",PostDate);
                    GenJrnl."Document No." := Doc;
                    GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                    GenJrnl.Validate("Account No.",ClearAcc);
                    GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2 - ' + Format(Buff."Payment Gate Way"), Buff."Shopify Order No",Buff."Shopify Order Date");
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                    GenJrnl.Validate(Amount,Buff."Order Total");
                    GenJrnl.Modify();
                    Buff."Apply Status" := Buff."Apply Status"::CashApplied;
                    Buff.Modify();
                    If Not TmpBuff1.Get(Buff."Shopify Order ID",Buff."Shopify Order Type") then
                    begin
                        TmpBuff1.Copy(Buff);
                        TmpBuff1.insert;
                    end;    
                until Buff.next = 0;
                Commit;
            end;
            GenJrnl.reset;
            GenJrnl.Setrange("Journal Template Name",'CASH RECE');
            GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
            If GenJrnl.findset then 
            Begin 
                If (Fee > 0) And (FeeAcc <> '') then
                begin
                    GenJrnl.INIT;
                    GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                    GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                    GenJrnl."Source Code" := 'CASHRECJNL';
                    LineNo += 10;
                    GenJrnl."Line No." := LineNo;
                    GenJrnl.INSERT(true);
                    GenJrnl.FILTERGROUP(2);
                    GenJrnl.VALIDATE("Posting Date",PostDate);
                    NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                    Doc := GenJrnl."Document No.";
                    GenJrnl.Validate("Account Type",GenJrnl."Account Type"::"G/L Account");
                    GenJrnl.Validate("Account No.",FeeAcc);
                    GenJrnl.Description := StrSubstNo('%1 Merchant Fees %2',Buff."Payment Gate Way",PostDate);
                    GenJrnl.validate("Gen. Posting Type",GenJrnl."Gen. Posting Type"::Purchase);
                    GenJrnl.validate("Gen. Bus. Posting Group",'DOMESTIC');
                    GenJrnl.validate("Gen. Prod. Posting Group",'MISC');
                    GenJrnl.validate("VAT Bus. Posting Group",'DOMESTIC');
                    GenJrnl.validate("VAT Prod. Posting Group",'GST10');
                    GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                    GenJrnl.Validate(Amount,Fee);
                    GenJrnl.validate("Bal. Account Type",GenJrnl."Bal. Account Type"::"Bank Account");
                    GenJrnl.Validate("Bal. Account No.",GLSetup."Reconcillation Bank Acc");
                    GenJrnl.Modify();
                end;    
                TmpBuff1.Reset;
                If TmpBuff1.Findset then
                repeat
                    If RecCon.get(TmpBuff1."Shopify Order ID",TmpBuff1."Shopify Order Type") then
                    begin
                        RecCon."Apply Status" := TmpBuff1."Apply Status";
                        RecCon.Modify();
                    end;
                until TmpBuff1.next = 0;
                Commit;    
            end;        
        end;    
        RecCon.Reset;
        RecCon.Setfilter("Order Total",'<=0');
        RecCon.Setrange("Apply Status",RecCon."Apply Status"::UnApplied,RecCon."Apply Status"::CashApplied);
        If RecCon.findset then
            RecCon.ModifyAll("Apply Status",RecCon."Apply Status"::Completed,false);
        // now we see what is cash applied that we may be able to invoice apply
        RecTot.reset;
        If RecTot.findset then RecTot.DeleteAll();
        RecCon.Reset;
        RecCon.SetCurrentKey("Order Total");
        RecCon.Setrange("Apply Status",RecCon."Apply Status"::CashApplied);
        If RecCon.findset Then
        repeat
            Clear(ClearAcc);
            Case RecCon."Payment Gate Way" of
                RecCon."Payment Gate Way"::"Shopify Pay": ClearAcc := GLSetup."Shopify Pay Clearing Acc"; 
                RecCon."Payment Gate Way"::Paypal: ClearAcc := GLSetup."PayPal Clearing Acc"; 
                RecCon."Payment Gate Way"::AfterPay :ClearAcc := GLSetup."AfterPay Clearing Acc"; 
                RecCon."Payment Gate Way"::Zip:ClearAcc := GLSetup."Zip Clearing Acc"; 
                RecCon."Payment Gate Way"::MarketPlace: ClearAcc := GLSetup."MarketPlace Clearing Acc"; 
                RecCon."Payment Gate Way"::Misc: ClearAcc := GLSetup."Misc Clearing Acc";
            end;     
            If ClearAcc <> '' then
            begin
                Clear(Doc);
                OrdHdr.Reset;
                OrdHdr.Setrange("Shopify Order ID",RecCon."Shopify Order ID");
                OrdHdr.SetFilter("Order Type",'%1|%2',OrdHdr."Order Type"::invoice,OrdHdr."Order Type"::Cancelled); 
                if RecCon."Shopify Order Type" = RecCon."Shopify Order Type"::Refund then
                    OrdHdr.SetRange("Order Type",OrdHdr."Order Type"::CreditMemo); 
                If OrdHdr.findset then
                begin
                    If Sinv.get(OrdHdr."BC Reference No.") AND (OrdHdr."Order Type" = OrdHdr."Order Type"::Invoice) then
                        Doc := Sinv."No."
                    else If Sinv.get(OrdHdr."BC Reference No.") AND (OrdHdr."Order Type" = OrdHdr."Order Type"::Cancelled) then
                        Doc := Sinv."No."
                    else If Scrd.get(OrdHdr."BC Reference No.") AND (OrdHdr."Order Type" = OrdHdr."Order Type"::CreditMemo) then
                        Doc := Scrd."No.";
                end;         
                If (Doc <> '') And (RecCon."Order Total" > 0) then
                begin
                    CustLed.reset;
                    CustLed.Setrange("Document Type",CustLed."Document Type"::Invoice);
                    if RecCon."Shopify Order Type" = RecCon."Shopify Order Type"::Refund then
                        CustLed.Setrange("Document Type",CustLed."Document Type"::"Credit Memo");
                    CustLed.Setrange("Document No.",Doc);
                    CustLed.setrange(Open,True);
                    Exflg := CustLed.findset;
                    If Exflg then
                    begin
                        CustLed.CalcFields("Remaining Amount");
                        If CustLed."Document Type" = CustLed."Document Type"::Invoice then
                            OrdFlg := Not RecTot.get(Doc,RecTot."Doc Type"::Invoice)
                        else
                            OrdFlg := Not RecTot.get(Doc,RecTot."Doc Type"::CreditNote);
                        If OrdFlg then
                        begin
                            RecTot.init;
                            RecTot."Doc No." := Doc;
                            RecTot."Doc Type" := RecTot."Doc Type"::Invoice;
                            If CustLed."Document Type" = CustLed."Document Type"::"Credit Memo" then
                                RecTot."Doc Type" := RecTot."Doc Type"::CreditNote;
                            Rectot.Total := ABS(CustLed."Remaining Amount");
                            RecTot.insert;
                        end;
                        RecTot.Totaliser += RecCon."Order Total";
                        RecTot.Modify();
                    end;
                    If Exflg then ExFlg := RecTot.Total >= RecTot.Totaliser;
                    If Exflg then
                    Begin
                        GenJrnl.INIT;
                        GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                        GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                        GenJrnl."Source Code" := 'CASHRECJNL';
                        LineNo += 10;
                        GenJrnl."Line No." := LineNo;
                        GenJrnl.INSERT(true);
                        GenJrnl.FILTERGROUP(2);
                        GenJrnl.VALIDATE("Posting Date",PostDate);
                        NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                        GenJrnl.VALIDATE("Account Type",GenJrnl."Account Type"::Customer);
                        GenJrnl.VALIDATE("Account No.",'PETCULTURE');
                        GenJrnl.Validate("Bal. Account Type",GenJrnl."Bal. Account Type"::"G/L Account");
                        GenJrnl.Validate("Bal. Account No.",ClearAcc);
                        GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2',RecCon."Shopify Order No",RecCon."Shopify Order Date");
                        If RecCon."Shopify Order Type" in [RecCon."Shopify Order Type"::Invoice,RecCon."Shopify Order Type"::Cancelled] then
                        begin
                            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                            GenJrnl.Validate(Amount,-RecCon."Order Total");
                            GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::Invoice;
                        end    
                        else
                        begin
                            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                            GenJrnl.Validate(Amount,RecCon."Order Total");
                            GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::"Credit Memo";
                        end;
                        GenJrnl."Applies-to Doc. No." := Doc;
                        GenJrnl.Modify();
                        If Not TmpBuff2.Get(RecCon."Shopify Order ID",RecCon."Shopify Order Type") then
                        Begin
                            TmpBuff2.Copy(RecCon);
                            TmpBuff2."Apply Status" := TmpBuff2."Apply Status"::Completed;
                            TmpBuff2.Insert();
                        end;        
                    end;
                end;
            end;
        until RecCon.Next = 0;
        Commit;
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then 
        Begin
            if Cu.Run(GenJrnl) then
            begin
                TmpBuff2.Reset;
                If TmpBuff2.Findset then
                repeat
                    If RecCon.get(TmpBuff2."Shopify Order ID",TmpBuff2."Shopify Order Type") then
                    begin
                        RecCon."Apply Status" := TmpBuff2."Apply Status";
                        RecCon.Modify();
                    end;
                until TmpBuff2.next = 0;    
            end
            Else
            begin
                TmpBuff1.Reset;
                If TmpBuff1.Findset then
                repeat
                    If RecCon.get(TmpBuff1."Shopify Order ID",TmpBuff1."Shopify Order Type") then
                    begin
                        RecCon."Apply Status" := RecCon."Apply Status"::UnApplied;
                        RecCon.Modify();
                    end;
                until TmpBuff1.next = 0;
                Message(GetLastErrorText());    
            end;    
        end;                
        If (PstDate[1] <> 0D) or (PstDate[2] <> 0D)  then
        begin
            GLSetup."Allow Posting To" := PstDate[1];
            GLSetup."Allow Posting From" := PstDate[2];
            GLSetup.Modify(false);
        end;
    end; 
    procedure Apply_Entries(PostDate:Date)
    var
        GenJrnlBatch:record "Gen. Journal Batch";
        GenJrnl:Record "Gen. Journal Line";
        GenTemplate:Record "Gen. Journal Template";
        NoSeriesMgt:Codeunit NoSeriesManagement;
        DummyCode:Code[10];
        GLSetup:Record "General Ledger Setup";
        ClearAcc:Code[20];
        Lineno:Integer;
        Sinv:Record "Sales Invoice Header";
        Scrd:record "Sales Cr.Memo Header";
        Doc:Code[20];
        GenJtrnTemp:Record "Gen. Journal Template";
        Cu:Codeunit "Gen. Jnl.-Post";
        PstDate:array[2] of date;
        OrdHdr:Record "PC Shopify Order Header";
        TmpBuff:record "PC Order Reconciliations" temporary;
        RecCon:Record "PC Order Reconciliations";
        CustLed:record "Cust. Ledger Entry";
        RecTot:Record "PC Reconciliation Totaler" temporary;
        ExFlg:Boolean;
        OrdFlg:boolean;
        win:Dialog;
     begin
        TmpBuff.reset;
        If Tmpbuff.Findset then Tmpbuff.DeleteAll();
        GLSetup.get;
        If GLSetup."Reconcillation Bank Acc" = '' then
        begin
            Message('Reconcilliation Bank acc not defined in General Ledger Setup');
            exit;
        end;
        If GLSetup."Shopify Pay Clearing Acc" = '' then
        begin
            Message('Shopify Pay Clearing acc not defined in General Ledger Setup');
            exit;
        end;
        If GLSetup."PayPal Clearing Acc" = '' then
        begin
            Message('PayPal Clearing acc not defined in General Ledger Setup');
            exit;
        end;  
        If GLSetup."AfterPay Clearing Acc" = '' then
        begin
            Message('After Pay Clearing acc not defined in General Ledger Setup');
            exit;
        end;    
        If GLSetup."MarketPlace Clearing Acc" = '' then
        begin
            Message('MarketPlace Clearing acc not defined in General Ledger Setup');
            exit;
        end;    
        If GLSetup."Zip Clearing Acc" = '' then
        begin
            Message('Zip Clearing acc not defined in General Ledger Setup');
            exit;
        end;    
        If GLSetup."Misc Clearing Acc" = '' then
        begin
            Message('Misc Clearing acc not defined in General Ledger Setup');
            exit;
        end;    
        If Not GenJtrnTemp.Get('CASH RECE') then
        begin
            GenJtrnTemp.Init();
            GenJtrnTemp.Validate(Name,'CASH RECE');
            GenJtrnTemp.insert;
            GenJtrnTemp.Description := 'Cash Receipts journal';
            GenJtrnTemp.validate(Type,GenJtrnTemp.type::"Cash Receipts");
            GenJtrnTemp.Validate("Bal. Account Type",GenJtrnTemp."Bal. Account Type"::"G/L Account");
            GenJtrnTemp.Validate("Source Code",'CASHRECJNL');
            GenJtrnTemp.Validate("Force Doc. Balance",true);
            GenJtrnTemp.Validate("Copy VAT Setup to Jnl. Lines",true);
            GenJtrnTemp.validate("Copy to Posted Jnl. Lines",true);
            GenJtrnTemp.Modify();
        end;
        If Not GenJrnlBatch.Get('CASH RECE','DEFAULT') then
        begin
            GenJrnlBatch.init;
            GenJrnlBatch.validate("Journal Template Name",'CASH RECE');
            GenJrnlBatch.Validate(Name,'DEFAULT');
            GenJrnlBatch.Insert();
            GenJrnlBatch.Validate("Bal. Account Type",GenJrnlBatch."Bal. Account Type"::"G/L Account");
            GenJrnlBatch.Validate("No. Series",'GJNL-RCPT');
            GenJrnlBatch.modify();
        end;
        Clear(PstDate);
        If (GLSetup."Allow Posting To" <> 0D) Or(GLSetup."Allow Posting From" <> 0D) then 
        begin
            PstDate[1] := GLSetup."Allow Posting To";
            PstDate[2] := GLSetup."Allow Posting From";
            Clear(GLSetup."Allow Posting To");
            Clear(GLSetup."Allow Posting From");
            GLSetup.MOdify(false);       
        end;
        Clear(Lineno);
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then GenJrnl.DeleteAll();
        Win.open('Processing Order No #1#############');
        RecTot.reset;
        If RecTot.findset then RecTot.DeleteAll();
        RecCon.Reset;
        RecCon.Setfilter("Order Total",'<=0');
        RecCon.Setrange("Apply Status",RecCon."Apply Status"::UnApplied,RecCon."Apply Status"::CashApplied);
        If RecCon.findset then
            RecCon.ModifyAll("Apply Status",RecCon."Apply Status"::Completed,false);
        RecCon.Reset;
        RecCon.SetCurrentKey("Order Total");
        RecCon.Setrange("Apply Status",RecCon."Apply Status"::CashApplied);
        If RecCon.findset Then
        repeat
            Clear(ClearAcc);
            Case RecCon."Payment Gate Way" of
                RecCon."Payment Gate Way"::"Shopify Pay": ClearAcc := GLSetup."Shopify Pay Clearing Acc"; 
                RecCon."Payment Gate Way"::Paypal: ClearAcc := GLSetup."PayPal Clearing Acc"; 
                RecCon."Payment Gate Way"::AfterPay :ClearAcc := GLSetup."AfterPay Clearing Acc"; 
                RecCon."Payment Gate Way"::Zip:ClearAcc := GLSetup."Zip Clearing Acc"; 
                RecCon."Payment Gate Way"::MarketPlace: ClearAcc := GLSetup."MarketPlace Clearing Acc"; 
                RecCon."Payment Gate Way"::Misc: ClearAcc := GLSetup."Misc Clearing Acc";
            end;     
            If ClearAcc <> '' then
            begin
                Clear(Doc);
                OrdHdr.Reset;
                OrdHdr.Setrange("Shopify Order ID",RecCon."Shopify Order ID");
                OrdHdr.SetFilter("Order Type",'%1|%2',OrdHdr."Order Type"::invoice,OrdHdr."Order Type"::Cancelled); 
                if RecCon."Shopify Order Type" = RecCon."Shopify Order Type"::Refund then
                    OrdHdr.SetRange("Order Type",OrdHdr."Order Type"::CreditMemo); 
                If OrdHdr.findset then
                begin
                    If Sinv.get(OrdHdr."BC Reference No.") AND (OrdHdr."Order Type" = OrdHdr."Order Type"::Invoice) then
                        Doc := Sinv."No."
                    else If Sinv.get(OrdHdr."BC Reference No.") AND (OrdHdr."Order Type" = OrdHdr."Order Type"::Cancelled) then
                        Doc := Sinv."No."
                    else If Scrd.get(OrdHdr."BC Reference No.") AND (OrdHdr."Order Type" = OrdHdr."Order Type"::CreditMemo) then
                        Doc := Scrd."No.";
                end;         
                If (Doc <> '') And (RecCon."Order Total" > 0) then
                begin
                    CustLed.reset;
                    CustLed.Setrange("Document Type",CustLed."Document Type"::Invoice);
                    if RecCon."Shopify Order Type" = RecCon."Shopify Order Type"::Refund then
                        CustLed.Setrange("Document Type",CustLed."Document Type"::"Credit Memo");
                    CustLed.Setrange("Document No.",Doc);
                    CustLed.setrange(Open,True);
                    Exflg := CustLed.findset;
                    If Exflg then
                    begin
                        CustLed.CalcFields("Remaining Amount");
                        If CustLed."Document Type" = CustLed."Document Type"::Invoice then
                            OrdFlg := Not RecTot.get(Doc,RecTot."Doc Type"::Invoice)
                        else
                            OrdFlg := Not RecTot.get(Doc,RecTot."Doc Type"::CreditNote);
                        If OrdFlg then
                        begin
                            RecTot.init;
                            RecTot."Doc No." := Doc;
                            RecTot."Doc Type" := RecTot."Doc Type"::Invoice;
                            If CustLed."Document Type" = CustLed."Document Type"::"Credit Memo" then
                                RecTot."Doc Type" := RecTot."Doc Type"::CreditNote;
                            Rectot.Total := ABS(CustLed."Remaining Amount");
                            RecTot.insert;
                        end;
                        RecTot.Totaliser += RecCon."Order Total";
                        RecTot.Modify();
                    end;
                    If Exflg then ExFlg := RecTot.Total >= RecTot.Totaliser;
                    If Exflg then
                    Begin
                        win.Update(1,Doc);
                        GenJrnl.INIT;
                        GenJrnl.VALIDATE("Journal Template Name",'CASH RECE');
                        GenJrnl.VALIDATE("Journal Batch Name",'DEFAULT');
                        GenJrnl."Source Code" := 'CASHRECJNL';
                        LineNo += 10;
                        GenJrnl."Line No." := LineNo;
                        GenJrnl.INSERT(true);
                        GenJrnl.FILTERGROUP(2);
                        GenJrnl.VALIDATE("Posting Date",PostDate);
                        NoSeriesMgt.InitSeries('GJNL-RCPT','',GenJrnl."Posting Date",GenJrnl."Document No.",DummyCode);
                        GenJrnl.VALIDATE("Account Type",GenJrnl."Account Type"::Customer);
                        GenJrnl.VALIDATE("Account No.",'PETCULTURE');
                        GenJrnl.Validate("Bal. Account Type",GenJrnl."Bal. Account Type"::"G/L Account");
                        GenJrnl.Validate("Bal. Account No.",ClearAcc);
                        GenJrnl.Description := StrSubstNo('Shopify Order No %1 for Order Date %2',RecCon."Shopify Order No",RecCon."Shopify Order Date");
                        If RecCon."Shopify Order Type" in [RecCon."Shopify Order Type"::Invoice,RecCon."Shopify Order Type"::Cancelled] then
                        begin
                            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Payment);
                            GenJrnl.Validate(Amount,-RecCon."Order Total");
                            GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::Invoice;
                        end    
                        else
                        begin
                            GenJrnl.Validate("Document Type",GenJrnl."Document Type"::Refund);
                            GenJrnl.Validate(Amount,RecCon."Order Total");
                            GenJrnl."Applies-to Doc. Type" := GenJrnl."Applies-to Doc. Type"::"Credit Memo";
                        end;
                        GenJrnl."Applies-to Doc. No." := Doc;
                        GenJrnl.Modify();
                        If Not TmpBuff.Get(RecCon."Shopify Order ID",RecCon."Shopify Order Type") then
                        Begin
                            TmpBuff.Copy(RecCon);
                            TmpBuff."Apply Status" := TmpBuff."Apply Status"::Completed;
                            TmpBuff.Insert();
                        end;        
                    end;
                end;
            end;
        until RecCon.Next = 0;
        win.CLose;
        Commit;
        Clear(Lineno);
        GenJrnl.reset;
        GenJrnl.Setrange("Journal Template Name",'CASH RECE');
        GenJrnl.Setrange("Journal Batch Name",'DEFAULT');
        If GenJrnl.findset then 
        Begin
            if Cu.Run(GenJrnl) then
            begin
                TmpBuff.Reset;
                If TmpBuff.Findset then
                repeat
                    If RecCon.get(TmpBuff."Shopify Order ID",TmpBuff."Shopify Order Type") then
                    begin
                        Lineno += 1;
                        RecCon."Apply Status" := TmpBuff."Apply Status";
                        RecCon.Modify();
                    end;
                until TmpBuff.next = 0;
                Message('%1 Entries have been Applied Successfully',Lineno);    
            end
            Else
               Message(GetLastErrorText());    
        end
        else
            Message('No Documents Found to apply Entries');
        If (PstDate[1] <> 0D) or (PstDate[2] <> 0D)  then
        begin
            GLSetup."Allow Posting To" := PstDate[1];
            GLSetup."Allow Posting From" := PstDate[2];
            GLSetup.Modify(false);
        end;
    end;
    Procedure Reverse_Reconcillation_Transactions(Doc:Code[20])
    var
        Recon:record "PC Order Reconciliations";
        OrdIDs:list of [text];    
        OrdHdr:record "PC Shopify Order Header";
        i:integer;
        CustLedg:Record "Cust. Ledger Entry";
        CustLedgTmp:record "Cust. Ledger Entry" temporary;
        DetCustLedg:record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ReversalEntry: Record "Reversal Entry";
        win:Dialog;
        Flg:Boolean;
        GLSetup:Record "General Ledger Setup";
        PSTDate:array[2] of date;
     begin
        Clear(PstDate);
        GLSetup.get;
        If (GLSetup."Allow Posting To" <> 0D) Or(GLSetup."Allow Posting From" <> 0D) then 
        begin
            PstDate[1] := GLSetup."Allow Posting To";
            PstDate[2] := GLSetup."Allow Posting From";
            Clear(GLSetup."Allow Posting To");
            Clear(GLSetup."Allow Posting From");
            GLSetup.MOdify(false);       
        end;
        Recon.Reset;
        If Doc = '' then
            Recon.Setrange("Apply Status",Recon."Apply Status"::Completed)
        else
            Recon.Setrange("Apply Status",Recon."Apply Status"::CashApplied,Recon."Apply Status"::Completed);    
        Recon.Setfilter("Order Total",'>0');
        If Recon.Findset then
        repeat
            OrdHdr.Reset();
            OrdHdr.Setrange("Shopify Order ID",Recon."Shopify Order ID");
            OrdHdr.Setrange("Order Type",Recon."Shopify Order Type");
            if Doc <> '' then
                OrdHdr.Setrange(OrdHdr."BC Reference No.",Doc);
            If OrdHdr.FindSet() then
                If Not OrdIDs.Contains(OrdHdr."BC Reference No.") then
                    OrdIDs.Add(OrdHdr."BC Reference No.");
        until Recon.next = 0;
        Win.open('Reversing Reconcillations For Doc #1##############'
                +'Action #2##################');
        For i := 1 to OrdIDs.Count do
        begin
            Win.Update(1,OrdIDs.Get(i));
            CustLedg.Reset();
            CustLedg.setrange("Document No.",OrdIDs.Get(i));
            If CustLedg.findset then
            begin
                CustLedgTmp.reset;
                if CustLedgTmp.findset then Custledgtmp.DeleteAll(False);
                FindApplnEntriesDtldtLedgEntry(CustLedg."Entry No.",CustLedgTmp);
                CustLedgTmp.Reset;
                CustLedgTmp.SetAscending("Entry No.",False);
                If CustLedgTmp.findset then
                repeat
                    // here we unapply the entries from the document
                    DetCustLedg.reset;
                    DetCustLedg.Setrange("Applied Cust. Ledger Entry No.",CustLedgTmp."Entry No.");
                    DetCustLedg.Setrange(Unapplied,False);
                    If DetCustLedg.FindSet() then
                    begin
                        Win.Update(2,'Unapplying Entries');
                        ApplyUnapplyParameters."Document No." := CustLedgTmp."Document No.";
                        ApplyUnapplyParameters."Posting Date" := DetCustLedg."Posting Date";
                        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetCustLedg, ApplyUnapplyParameters);
                    end;  
                    if Not CustLedgTmp.Reversed And (CustLedgTmp."Transaction No." > 0) then
                    Begin
                        Win.Update(2,'Reversing Entries');
                        ReversalEntry.SetHideWarningDialogs();
                        ReversalEntry.ReverseTransaction(CustLedgTmp."Transaction No.");
                    end;    
                Until CustLedgTmp.next = 0;
            end;    
        end;
        If Doc = '' then
        begin
            Recon.Reset;
            Recon.Setrange("Apply Status",recon."Apply Status"::Completed);    
            Recon.Setfilter("Order Total",'>0');
            If Recon.Findset then
                Recon.ModifyAll("Apply Status",Recon."Apply Status"::CashApplied,False);
        end
        else  
        Begin        
            Recon.Reset;
            Recon.Setrange("Apply Status",Recon."Apply Status"::CashApplied,Recon."Apply Status"::Completed);    
            Recon.Setfilter("Order Total",'>0');
            If Recon.Findset then
            repeat
                OrdHdr.Reset();
                OrdHdr.Setrange("Shopify Order ID",Recon."Shopify Order ID");
                OrdHdr.Setrange("Order Type",Recon."Shopify Order Type");
                OrdHdr.Setrange(OrdHdr."BC Reference No.",Doc);
                If OrdHdr.FindSet() then
                begin
                    If Recon."Apply Status" = Recon."Apply Status"::CashApplied then
                        Recon."Apply Status" := Recon."Apply Status"::UnApplied
                    else
                        Recon."Apply Status" := Recon."Apply Status"::CashApplied;    
                    Recon.Modify(False);
                end;
            until Recon.next = 0;
        end;    
        Win.Close();
        If (PstDate[1] <> 0D) or (PstDate[2] <> 0D)  then
        begin
            GLSetup."Allow Posting To" := PstDate[1];
            GLSetup."Allow Posting From" := PstDate[2];
            GLSetup.Modify(false);
        end;
    end;    
    Procedure Reverse_Reconcillation_TransactionsEX(Doc:Code[20])
    var
        Recon:record "PC Order Reconciliations";
        OrdIDs:list of [text];    
        OrdHdr:record "PC Shopify Order Header";
        i:integer;
        CustLedg:Record "Cust. Ledger Entry";
        CustLedgTmp:record "Cust. Ledger Entry" temporary;
        DetCustLedg:record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ReversalEntry: Record "Reversal Entry";
        win:Dialog;
        Flg:Boolean;
        GLSetup:Record "General Ledger Setup";
        PSTDate:array[2] of date;
     begin
        Clear(PstDate);
        GLSetup.get;
        If (GLSetup."Allow Posting To" <> 0D) Or (GLSetup."Allow Posting From" <> 0D) then 
        begin
            PstDate[1] := GLSetup."Allow Posting To";
            PstDate[2] := GLSetup."Allow Posting From";
            Clear(GLSetup."Allow Posting To");
            Clear(GLSetup."Allow Posting From");
            GLSetup.MOdify(false);       
        end;
        Recon.Reset;
        Recon.Setfilter("Order Total",'>0');
        Recon.Setrange("Apply Status",Recon."Apply Status"::CashApplied);
        If Recon.Findset then
        repeat
            OrdHdr.Reset();
            OrdHdr.Setrange("Shopify Order ID",Recon."Shopify Order ID");
            OrdHdr.Setrange("Order Type",Recon."Shopify Order Type");
            OrdHdr.Setfilter("BC Reference No.",'<>%1','');
            If OrdHdr.FindSet() then
                If Not OrdIDs.Contains(OrdHdr."BC Reference No.") then
                    OrdIDs.Add(OrdHdr."BC Reference No.");
        until Recon.next = 0;
        Win.open('Reversing Reconcillations For Doc #1##############'
                +'Action #2##################');
        For i := 1 to OrdIDs.Count do
        begin
            Win.Update(1,OrdIDs.Get(i));
            CustLedg.Reset();
            CustLedg.setrange("Document No.",OrdIDs.Get(i));
            If CustLedg.findset then
            begin
                CustLedgTmp.reset;
                if CustLedgTmp.findset then Custledgtmp.DeleteAll(False);
                FindApplnEntriesDtldtLedgEntry(CustLedg."Entry No.",CustLedgTmp);
                CustLedgTmp.Reset;
                CustLedgTmp.SetAscending("Entry No.",False);
                If CustLedgTmp.findset then
                repeat
                    // here we unapply the entries from the document
                    DetCustLedg.reset;
                    DetCustLedg.Setrange("Applied Cust. Ledger Entry No.",CustLedgTmp."Entry No.");
                    DetCustLedg.Setrange(Unapplied,False);
                    If DetCustLedg.FindSet() then
                    begin
                        Win.Update(2,'Unapplying Entries');
                        ApplyUnapplyParameters."Document No." := CustLedgTmp."Document No.";
                        ApplyUnapplyParameters."Posting Date" := DetCustLedg."Posting Date";
                        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetCustLedg, ApplyUnapplyParameters);
                    end;  
                    if Not CustLedgTmp.Reversed And (CustLedgTmp."Transaction No." > 0) then
                    Begin
                        Win.Update(2,'Reversing Entries');
                        ReversalEntry.SetHideWarningDialogs();
                        ReversalEntry.ReverseTransaction(CustLedgTmp."Transaction No.");
                    end;    
                Until CustLedgTmp.next = 0;
            end;    
        end;
        /*Recon.Reset;
        Recon.Setfilter("Order Total",'>0');
        If Recon.Findset then
        repeat
            OrdHdr.Reset();
            OrdHdr.Setrange("Shopify Order ID",Recon."Shopify Order ID");
            OrdHdr.Setrange("Order Type",Recon."Shopify Order Type");
            OrdHdr.Setrange(OrdHdr."BC Reference No.",Doc);
            If OrdHdr.FindSet() then
            begin
                Recon."Apply Status" := Recon."Apply Status"::UnApplied;
                Recon.Modify(False);
            end;
        until Recon.next = 0;*/
        If (PstDate[1] <> 0D) or (PstDate[2] <> 0D)  then
        begin
            GLSetup."Allow Posting To" := PstDate[1];
            GLSetup."Allow Posting From" := PstDate[2];
            GLSetup.Modify(false);
        end;
    end;    
    local procedure FindApplnEntriesDtldtLedgEntry(EntryNo:integer;Var Custledgtmp:Record "Cust. Ledger Entry" temporary);
    var
        DtldCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustLedg:Record "Cust. Ledger Entry";
    begin
        DtldCustLedgEntry1.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry1.SetRange("Cust. Ledger Entry No.", EntryNo);
        DtldCustLedgEntry1.SetRange(Unapplied, false);
        if DtldCustLedgEntry1.Find('-') then
        repeat
            if DtldCustLedgEntry1."Cust. Ledger Entry No." = DtldCustLedgEntry1."Applied Cust. Ledger Entry No." then 
            begin
                DtldCustLedgEntry2.Init();
                DtldCustLedgEntry2.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                DtldCustLedgEntry2.SetRange("Applied Cust. Ledger Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                DtldCustLedgEntry2.SetRange("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                DtldCustLedgEntry2.SetRange(Unapplied, false);
                if DtldCustLedgEntry2.Find('-') then
                repeat
                    if DtldCustLedgEntry2."Cust. Ledger Entry No." <> DtldCustLedgEntry2."Applied Cust. Ledger Entry No." then 
                    begin
                        CustLedg.SetCurrentKey("Entry No.");
                        CustLedg.SetRange("Entry No.", DtldCustLedgEntry2."Cust. Ledger Entry No.");
                        if CustLedg.Find('-') then
                            If Not Custledgtmp.get(Custledg."Entry No.") then
                            begin
                                Custledgtmp.copy(CustLedg);
                                Custledgtmp.insert(False);
                            end;
                    end;
                until DtldCustLedgEntry2.Next() = 0;
            end else 
            begin
                CustLedg.SetCurrentKey("Entry No.");
                CustLedg.SetRange("Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                if CustLedg.Find('-') then
                    If Not Custledgtmp.get(Custledg."Entry No.") then
                    begin
                        Custledgtmp.copy(CustLedg);
                            Custledgtmp.insert(False);
                    end;
            end;
        until DtldCustLedgEntry1.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostUnApplyCustomerCommit', '', true, true)]
    local procedure "CustEntry-Apply Posted Entries_OnBeforePostUnApplyCustomerCommit"
    (
        var HideProgressWindow: Boolean;
		PreviewMode: Boolean;
		DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
		DocNo: Code[20];
		PostingDate: Date;
		CommitChanges: Boolean;
		var IsHandled: Boolean
    )
    begin
        HideProgressWindow := True;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post", 'OnBeforeCode', '', true, true)]
    local procedure "Gen. Jnl.-Post_OnBeforeCode"
    (
        var GenJournalLine: Record "Gen. Journal Line";
		var HideDialog: Boolean
    )
    begin
        HideDialog := True;
    end;
  
}
