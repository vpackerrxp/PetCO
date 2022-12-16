codeunit  80006 Test
{
     Permissions = TableData "Sales Invoice Line" = rm,tabledata "Sales Cr.Memo Line" = rm
                 ,tabledata "Purch. Inv. Line" = rm,tabledata "Purch. Rcpt. Line" = rm;        
var
        Paction:Option GET,POST,DELETE,PATCH,PUT;
        WsError:text;
        ShopifyBase:Label '/admin/api/2021-10/';
    trigger OnRun()
    Begin
        Error('This is a test for Vic');
    End;
    procedure Fix_Rebate_Suppliers()
    var
        suppBrand:Record "PC Supplier Brand Rebates";
        PCReb:record "PC Purchase Rebates";
        PILine:record "Purch. Inv. Line";
        PRec:record "Purch. Rcpt. Line";
        Item:record Item;
        POLine:Record "Purchase Line";
        PH:record "Purchase Header";
        Flg:Boolean;
    begin
        PH.reset;
        PH.setrange("Document Type",PH."Document Type"::Order);
        PH.setrange("Order Type",PH."Order Type"::Fulfilo);
        If PH.Findset then
        repeat
            Flg := PH.Status = PH.Status::Released;
            If Flg then
            begin
                PH.Status := PH.Status::Open;
                Ph.Modify(False);
            end;    
            POLine.reset;
            POLine.Setrange(Type,POLine.Type::Item);
            POLine.Setrange("Document Type",PH."Document Type");
            POLine.Setrange("Document No.",PH."No.");
            POLine.Setrange(Brand,'');
            If POLine.FindSet() then
            Repeat
                Item.Get(POLine."No.");
                If Not Item."Purchasing Blocked" then
                Begin
                    POLine.Validate("No.");
                    POline.Modify(False);
                end;    
            Until POLine.next = 0;
            If Flg then
            begin
                PH.Status := PH.Status::Released;
                Ph.Modify(False);
            end; 
        until PH.next = 0;       
        PILine.reset;
        PILine.Setrange(Type,PILine.Type::Item);
        PILine.Setrange(Brand,'');
        If PILine.Findset then
        repeat
            If Item.Get(PILine."No.") then
            begin
                PILine.Brand := Item.BRand;
                suppBrand.Reset;
                suppBrand.Setrange(Brand,PIline.Brand);
                If suppBrand.FindSet() then
                    PILine."Rebate Supplier No." := suppBrand."Rebate Supplier No.";
                PILine.Modify(false);    
            end;    
        until PILine.Next = 0;
        PRec.reset;
        PRec.Setrange(Type,PRec.Type::Item);
        PRec.SetRange(Brand,'');
        If Prec.Findset then
        repeat
            If Item.Get(PILine."No.") then
            begin
                Prec.Brand := Item.BRand;
                suppBrand.Reset;
                suppBrand.Setrange(Brand,Prec.Brand);
                If suppBrand.FindSet() then
                    Prec."Rebate Supplier No." := suppBrand."Rebate Supplier No.";
                Prec.Modify(false);    
            end;    
        until PRec.Next = 0;
    end;    
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

       procedure Fix_market_Place()
    var
        Recon:record "PC Order Reconciliations";
        CU:Codeunit "PC Shopify Routines";
        win:dialog;
        i:Integer;
    begin
        win.Open('Fixing Record #1######## of #2#######');
        Clear(i);
        Recon.Reset;
        Recon.Setrange("Payment Gate Way",Recon."Payment Gate Way"::MarketPlace);
        Recon.Setrange("Reference No",'');
        If Recon.FindSet() then
        begin
            win.update(2,Recon.Count);
            repeat
                i+=1;
                CU.Get_Order_Reconciliation_Transactions(Recon);
                win.update(1,i);
                Recon.Modify(false);
            until Recon.Next = 0;
        end;    
        win.close;
    end;

    Procedure Fix_Rebates()
    var 
        SalesInv:Record "Sales Invoice Line";
        SalesInv2:Record  "Sales Invoice Line";
        SalesHdr:Record "Sales Header";
        SLine:Record "Sales Line";
        lineNo:Integer;
        RebateTot:array[2] of Decimal;
        RebateSum:array[2] of Decimal;
        RebDesc:array[2] of Code[20];
        i:Integer;
    begin
        Clear(SalesHdr);
        SalesHdr.init;
        SalesHdr.validate("Document Type",SalesHdr."Document Type"::Invoice);
        SalesHdr.Validate("Sell-to Customer No.",'PETCULTURE');
        SalesHdr.validate("Prices Including VAT",True);
        SalesHdr."Your Reference" := 'SHOPIFY ORDERS';
        SalesHdr.Insert(true);
        Clear(LineNo);
        Clear(RebateTot);
        Clear(RebDesc);
        SalesInv.Reset;
        SalesInv.Setrange("Sell-to Customer No.",'PETCULTURE');
        SalesInv.Setfilter("Document No.",'INV-00002794..');
        SalesInv.Setrange(Type,SalesInv.Type::Item);
        If SalesInv.Findset then
        repeat
            Clear(SalesInv."Campaign Rebate");
            Clear(SalesInv."Campaign Rebate Amount");
            Clear(SalesInv."Campaign Rebate Code");
            Clear(SalesInv."Campaign Rebate Supplier");
            Clear(SalesInv."Auto Delivery Rebate Amount");
            Clear(SalesInv."Auto Delivery Rebate Code");
            Clear(SalesInv."Auto Delivery Rebate Supplier");         
            Sline.Init;
            SLine."Document No." := SalesHdr."No.";
            SLine."Document Type" := SalesHdr."Document Type";
            Sline."Shopify Order Date" := SalesInv."Shopify Order Date";
            Sline."Shopify Order ID" := SalesInv."Shopify Order ID";
            Sline."Shopify Order No" := SalesInv."Shopify Order No";
            Sline."No." := SalesInv."No.";
            Sline.Quantity := SalesInv.Quantity;
            Sline."Auto Delivered" := SalesInv."Auto Delivered";
            Sline."Rebate Supplier No." := SalesInv."Rebate Supplier No.";
            Add_Rebate_Entries(Sline,LineNo,RebateTot,RebDesc);
            SalesInv."Campaign Rebate" := Sline."Campaign Rebate";
            SalesInv."Campaign Rebate Amount" := Sline."Campaign Rebate Amount";
            SalesInv."Campaign Rebate Code" := Sline."Campaign Rebate Code";
            SalesInv."Campaign Rebate Supplier" := Sline."Campaign Rebate Supplier";
            SalesInv."Auto Delivery Rebate Amount" := Sline."Auto Delivery Rebate Amount";
            SalesInv."Auto Delivery Rebate Code" := Sline."Auto Delivery Rebate Code";
            SalesInv."Auto Delivery Rebate Supplier" := Sline."Auto Delivery Rebate Supplier";
            SalesInv.modify(false);
        Until SalesInv.next = 0;





/*        For i := 1 to 2 do 
            If Rebatetot[i] > 0 then
            begin
                LineNo += 10;
                Clear(SLine);
                SLine.init;
                SLine.Validate("Document Type",SalesHdr."Document Type");
                SLine.Validate("Document No.",SalesHdr."No.");
                SLine."Line No." := LineNo;
                Sline.insert(true);
                SLine.Validate(Type,SLine.TYpe::Item);
                If i = 1 then
                    SLine.validate("No.",'REBATE_REV_CAMP')
                else
                    SLine.validate("No.",'REBATE_REV_AUTO');
                SLine.Validate("VAT Prod. Posting Group",'NO GST');
                SLine.Validate("Unit of Measure Code",'EA');    
                SLine.Validate(Quantity,1);
                Clear(Sline."Auto Delivered");
                Sline.Validate("Unit Price",-Rebatetot[i]);
                If i = 1 then
                begin
                    SLine.Description := 'Campaign Rebate ' + RebDesc[i];
                    SLine."Campaign Rebate Code" := RebDesc[i];
                end
                else
                begin
                    SLine.Description := 'Auto Delivery Rebate ' + RebDesc[i];
                    SLine."Auto Delivery Rebate Code" := RebDesc[i];
                end;    
                SLine.Modify(true);
            end;
        SalesInv.Reset;
        SalesInv.Setrange("Document No.",'INV-00002828');
        SalesInv.Setrange(Type,SalesInv.Type::"G/L Account");
        If SalesInv.Findset then
        repeat
            SalesInv2.Reset;
            SalesInv2.Setrange("Shopify Order ID",)

        Until SalesInv.next = 0;
*/





    end;

    local procedure Add_Rebate_Entries(var SLine:record "Sales Line";var Lineno:Integer;Var RebateTot:Array[2] of Decimal;var RDesc:array[2] of Code[20])
    var
        CmpReb:Record "PC Campaign Rebates";
        CmpSku:record "PC Campaign SKU New";
        SalesLine:Record "Sales Line";
        i:Integer;
        RunFlg:Boolean;
        GLSetup:Record "General Ledger Setup";
        PurchCst:record "PC Purchase Pricing";
    begin
        GLSetup.get;
        For i := 1 to 2 do
        begin
            CmpReb.reset;
            Clear(RunFlg);
            Case i Of 
                1:
                begin
                    CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::Campaign);
                    CmpReb.SetFilter("Campaign Start Date",'>%1&<=%2',0D,SLine."Shopify Order Date");
                    CmpReb.SetFilter("Campaign End Date",'>=%1',SLine."Shopify Order Date");
                    RunFlg := True;
                end;
                2:
                begin
                    CmpReb.Setrange("Rebate Type",CmpReb."Rebate Type"::"Auto Delivery");
                    RunFlg := Sline."Auto Delivered";
                end;    
            end;
            If RunFlg then
                If CmpReb.findset then
                repeat
                    CmpSku.Reset;
                    CmpSku.Setrange("Rebate Supplier No.",CmpReb."Rebate Supplier No.");
                    CmpSku.Setrange(Campaign,CmpReb.Campaign);
                    CmpSku.Setrange(SKU,SLine."No.");
                    CmpSku.SetFilter("Rebate Amount",'>0');
                    If CmpSku.findset then
                    begin
                        PurchCst.Reset;
                        PurchCst.SetCurrentKey("End Date");
                        PurchCst.SetAscending("End Date",false);
                        PurchCst.Setrange("Item No.",CmpSku.SKU);
                        PurchCst.Setrange("Supplier Code",SLine."Rebate Supplier No.");
                        PurchCst.SetFilter("Start Date",'<=%1',SLine."Shopify Order Date");
                        PurchCst.Setfilter("End Date",'%1|>=%2',0D,SLine."Shopify Order Date");
                        If PurchCst.Findset then
                        begin
                            LineNo += 10;
                            Clear(SalesLine);
                            SalesLine.init;
                            SalesLine.Validate("Document Type",SLine."Document Type");
                            SalesLine.Validate("Document No.",SLine."Document No.");
                            SalesLine."Line No." := LineNo;
                            Salesline.insert(true);
                            SalesLine.Validate(Type,SalesLine.Type::"G/L Account");
                            // Rebate Amount entered as a percentage now
                            If i = 1 then
                            begin
                                SalesLine.validate("No.",GLSetup."Campaign Rebate Posting Acc");
                                SalesLine.Description := 'Campaign Rebate ' + CmpReb.Campaign;
                                SLine."Campaign Rebate" := True;
                                SLine."Campaign Rebate Supplier" := CmpReb."Rebate Supplier No.";
                                SLine."Campaign Rebate Amount" := ((PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100) * SLine.Quantity;
                                Sline."Campaign Rebate Code"  := CmpReb.Campaign;
                                Sline."Campaign Rebate %" := CmpSku."Rebate Amount";
                            end    
                            else
                            begin
                                SalesLine.validate("No.",Glsetup."Auto Order Rebate Posting Acc");
                                SalesLine.Description := 'Auto Delivery Rebate ' + CmpReb.Campaign;
                                SLine."Auto Delivery Rebate Supplier" := CmpReb."Rebate Supplier No.";
                                Sline."Auto Delivery Rebate Amount" := ((PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100) * SLine.Quantity;
                                Sline."Auto Delivery Rebate Code" := CmpReb.Campaign;
                                Sline."Auto Delivery Rebate %" := CmpSku."Rebate Amount";
                            end;    
                            SalesLine.Validate(Quantity,SLine.Quantity);
                            Salesline.Validate("Unit Price",(PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100);
                            RebateTot[i] += ((PurchCst."Unit Cost" * CmpSku."Rebate Amount")/100) * SLine.Quantity;
                            RDesc[i] := CmpReb.Campaign;
                            Salesline."Shopify Order ID" := SLine."Shopify Order ID";
                            SalesLine."Shopify Order Date" := Sline."Shopify Order Date";
                            SalesLine."Rebate Supplier No." := CmpReb."Rebate Supplier No.";
                            Salesline.Modify(true)
                        end;
                    end;    
                Until CmpReb.next = 0;
        end;
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
        CU1:Codeunit "PC Shopify Routines";
        Dates:array[2] of Date;
        RefID:BigInteger;
    begin
        //Evaluate(RefId,'4626154061935');
        //Cu1.Check_For_Extra_Refunds(0);
        //Exit;
        
        Recon.Reset;
        If Recon.Findset then
        repeat
            Recon."Shopify Display ID" := Recon."Shopify Order ID";
            Recon.Modify(false);
        until recon.next = 0;    
        Exit;    

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