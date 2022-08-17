tableextension 80001 "PC Items Ext" extends Item
{
    fields
    {
        modify("Vendor No.")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Vendor No." <> Rec."Vendor No.")  Then 
                    rec."Shopify Transfer Flag" := true;
            end; 
        }
        modify("Item Category Code")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Item Category Code" <> Rec."Item Category Code") Then 
                rec."Shopify Transfer Flag" := true;
            end; 
        }
        modify(Description)
        {
            trigger OnAfterValidate()
            begin
                If (Xrec.Description <> Rec.Description) then 
                    rec."Shopify Transfer Flag" := true;
             end;
        }
        modify("Description 2")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Description 2" <> Rec."Description 2") then 
                    rec."Shopify Transfer Flag" := true;
            end;
        }
        modify("Unit Cost")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Unit Cost" <> Rec."Unit Cost") then
                    rec."Shopify Transfer Flag" := true;
            end;
        }
        modify("Unit Price")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Unit Price" <> Rec."Unit Price") Then 
                    Rec."Shopify Transfer Flag" := true;
           end;    
        }
        modify("Base Unit of Measure")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Base Unit of Measure" <> Rec."Base Unit of Measure") Then
                    rec."Shopify Transfer Flag" := true;
            end;
        }
        modify("Vendor Item No.")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."Vendor Item No." <> Rec."Vendor Item No.") Then
                    rec."Shopify Transfer Flag" := true;
            end;
        }
        modify("GTIN")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."GTIN" <> Rec."GTIN") Then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;    
            end;
        }
        Modify("VAT Prod. Posting Group")
        {
            trigger OnAfterValidate()
            begin
                If (Xrec."VAT Prod. Posting Group" <> Rec."VAT Prod. Posting Group") Then
                begin
                    Rec."Price Includes VAT" := Rec."VAT Prod. Posting Group" = 'GST10';
                    Update_Parent(); 
                end;
           end;
        }
        field(80000; "Shopify Product ID"; biginteger)
        {
        }
        field(80001; "Shopify Product Variant ID"; biginteger)
        {
        }
        field(80002; "Shopify Product Inventory ID"; biginteger)
        {
            Editable = false;
        }
        field(80003; "Shopify Location Inventory ID"; biginteger)
        {
            Editable = false;
        }
        field(80004; "Shopify Title"; text[100])
        {
            trigger OnValidate()
            begin
                If (Xrec."Shopify Title" <> Rec."Shopify Title") then
                begin
                    rec."Key Info Changed Flag" := True;
                    rec."Shopify Transfer Flag" := true;
                end; 
             end;
        }    
        field(80005; "Shopify Body Html"; text[250])
        {
            trigger OnValidate()
            begin
                If (Xrec."Shopify Body Html" <> Rec."Shopify Body Html") Then
                Begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;            
        }    
        field(80006; "Shopify Item"; option)
        {
            OptionMembers = internal,Shopify;
        }
        field(80007; "Shopify Transfer Flag"; Boolean)
        {
        }
        field(80008; "Is In Shopify Flag"; Boolean)
        {
        }
        field(80009; "Key Info Changed Flag"; Boolean)
        {
        }
        field(80010; "Shopify Publish Flag"; Boolean)
        {
        }
        field(80011; "Reset Shopify Parent"; Boolean)
        {
            ObsoleteState = Removed;
        }
        field(80012; "Product Code"; Code[30])
        {
        }
        field(80013; "Brand"; Code[30])
        {
        }
        field(80014; "Is Child Flag"; Boolean)
        {
        }
        field(80015;"Sub Catergory Name";Text[50])
        {
            trigger OnValidate()
            begin
                If (Xrec."Sub Catergory Name"<> Rec."Sub Catergory Name") Then
                    rec."Shopify Transfer Flag" := true;
            end;        
        }
        Field(80016;"CRM Shopify Product ID";BigInteger)
        {}
        Field(80017;"Fulfilo Qty On PO";Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("Purchase Line"."Fulfilo Recvd Qty"
                        WHERE ("Document Type"=CONST(Order),Type=CONST(Item),"No."=FIELD("No.")
                              ,"Fulfilo Recvd Qty"=filter(>-1),"Location Code"=FIELD("Location Filter")));
            DecimalPlaces = 0:5;            
        }
        Field(80018;"Shopify Child Count";integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("PC Shopify Item Relations"
                          WHERE ("Parent Item No."=FIELD("No."),"Un Publish Child"=const(False)));
        }
        Field(80019;"Fulfilo Inventory";Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = Sum("PC Fulfilo Inventory"."Qty"
                        WHERE ("SKU"=FIELD("No."),"Location Code"=FIELD("Location Filter")));
            DecimalPlaces = 0:5;            
        }
        Field(80020;"Fulfilo Reason Count";Integer)
        {
            FieldClass = FlowField;
            CalcFormula = Count("PC Fulfilo Inv. Delta Reasons"
                        WHERE ("SKU"=FIELD("No."),"Location Code"=FIELD("Location Filter")));
        }
 
        Field(80021;"Auto Delivery";Boolean)
        {
            trigger OnValidate()
            begin
                If (Xrec."Auto Delivery"<> Rec."Auto Delivery") Then
                    rec."Shopify Transfer Flag" := true;
            end;        
        }
        field(80022;"Catergory Name";Text[50])
        {
            trigger OnValidate()
            begin
                If (Xrec."Catergory Name"<> Rec."Catergory Name") Then
                    rec."Shopify Transfer Flag" := true;
            end;        
        }
        field(80023; "Shopify Update Flag"; Boolean)
        {
        }
        field(80024; "Current RRP"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current RRP" <> Rec."Current RRP" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
           end;    
        }
        field(80025; "Current Price"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current Price" <> Rec."Current Price" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
           end;    
        }
        field(80026; "Current PDisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current PDisc" <> Rec."Current PDisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
        field(80027; "Current GDisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current GDisc" <> Rec."Current GDisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
        field(80028; "Current SDisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current SDisc" <> Rec."Current SDisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
        field(80029; "Current ADisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current ADisc" <> Rec."Current ADisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
        field(80030; "Current VDisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current VDisc" <> Rec."Current VDisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
       field(80031; "Current Width"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current Width" <> Rec."Current Width" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
       field(80032; "Current Length"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current Length" <> Rec."Current Length" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
        field(80033; "Current Height"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current Height" <> Rec."Current Height" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;    
            end;    
        }
        field(80034; "Current PlatADisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current PlatADisc" <> Rec."Current PlatADisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }

        field(80035; "Current GoldADisc"; Decimal)
        {
            trigger OnValidate()
            begin
                If xRec."Current GoldADisc" <> Rec."Current GoldADisc" then
                begin
                    rec."Shopify Transfer Flag" := true;
                    Update_Parent();
                end;
            end;    
        }
    }
    Procedure Update_Parent()
    var
        Rel:record "PC Shopify Item Relations";
        Item:record Item;
    begin
        Rel.Reset;
        Rel.Setrange("Child Item No.",Rec."No.");
        If Rel.Findset then
        begin
            Item.Get(Rel."Parent Item No.");
            If Not Item."Shopify Update Flag" then
            begin
                Item."Shopify Update Flag" := True;
                Item.MOdify(false);
            end;          
            Clear(rec."Shopify Update Flag");
        end;
    end;
    procedure Get_Price():Decimal
    var
        Sp:Record "PC Shopfiy Pricing";
        val:Decimal;
        RRP:decimal;
    begin
        Val := 99999;
        Clear(RRP);
        Sp.reset;
        Sp.Setrange("Item No.",rec."No.");
        SP.Setfilter("Starting Date",'<=%1',Today);
        SP.Setfilter("Ending Date",'%1|>=%2',0D,Today);
        if SP.FindSet() then
        repeat
            If Sp."Sell Price" < Val then 
            Begin
                val := Sp."Sell Price";
                RRP := Sp."New RRP Price";
            end;    
        Until Sp.next = 0;
        If (RRP > 0) and (RRP <> rec."Unit Price") then 
        begin
            rec."Unit Price" := RRP;
            rec.Modify(False);
            Commit;
        end;
        If val = 99999 then val := rec."Unit Price";
        exit(val);
    end;
    procedure Get_Shopify_Disc(SdiscIndx:Integer):Decimal;
    var 
        Sp:Record "PC Shopfiy Pricing";
        val:Decimal;
    begin
        Val := -1;
        Sp.reset;
        Sp.Setrange("Item No.",rec."No.");
        Case SDiscIndx of
            0:Sp.Setfilter("Platinum Member Disc %",'>0');
            1:Sp.Setfilter("Gold Member Disc %",'>0');
            2:Sp.Setfilter("Silver Member Disc %",'>0');
            3:Sp.Setfilter("VIP Disc %",'>0');
            4:Sp.Setfilter("Auto Order Disc %",'>0');
            5:Sp.Setfilter("Platinum + Auto Disc %",'>0');
            6:Sp.Setfilter("Gold + Auto Disc %",'>0');
        end;    
        SP.Setfilter("Starting Date",'<=%1',Today);
        SP.Setfilter("Ending Date",'%1|>=%2',0D,Today);
        if SP.FindSet() then
        repeat
            Case SDiscIndx of
                0:if Sp."Platinum Member Disc %" > Val then 
                    val := Sp."Platinum Member Disc %";
                1:if Sp."Gold Member Disc %" > Val then 
                    val := Sp."Gold Member Disc %";
                2:if Sp."Silver Member Disc %" > Val then 
                    val := Sp."Silver Member Disc %";
                3:if Sp."VIP Disc %" > Val then 
                    val := Sp."VIP Disc %";
                4:if Sp."Auto Order Disc %" > Val then 
                    val := Sp."Auto Order Disc %";
                5:if Sp."Platinum + Auto Disc %" > Val then 
                    val := Sp."PLatinum + Auto Disc %";
                6:if Sp."Gold + Auto Disc %" > Val then 
                    val := Sp."Gold + Auto Disc %";
            end;
        Until Sp.next = 0;
        If val = -1 then val := 0;
        exit(val);
    end;
    procedure Get_Product_Size(Sindx:Integer):Decimal
    var
        Itemunit:record "Item Unit of Measure";
    Begin
        If ItemUnit.get(rec."No.",rec."Base Unit of Measure") then
            case SIndx of
                0: Exit(Itemunit.Width);
                1: Exit(Itemunit.Length);
                2: Exit(Itemunit.Height);
            end    
        else
            exit(0);
    end;

    Procedure Get_Product_Dimensions(DimIndx:integer):Code[20]
    var
        DefDim:Record "Default Dimension";
        Dims:Code[20];
    begin
        Clear(Dims);
        Case Dimindx of
            0:if DefDim.Get(Database::Item,Rec."No.",'DEPARTMENT') then
                Dims := DefDim."Dimension Value Code";
            1:if DefDim.Get(Database::Item,Rec."No.",'CATEGORY') then
                Dims := DefDim."Dimension Value Code";
            2:if DefDim.Get(Database::Item,Rec."No.",'SUB-CATEGORY') then
                Dims := DefDim."Dimension Value Code";
        end;
        exit(Dims);
    end;
    Procedure Get_List_Cost():Decimal
    var
        PurchCst:record "PC Purchase Pricing"; 
    begin
        PurchCst.reset;
        PurchCst.Setrange("Supplier Code",rec."Vendor No.");
        PurcHCst.Setrange("Item No.",rec."No.");
        //PurchCst.SetFilter("Ending Date",'%1|>=%2',0D,Today);
        If PurchCst.findset then
            Exit(PurchCst."Unit Cost")
        else
            exit(0);     
    end;
    procedure Get_First_Costs():Decimal
    begin
        exit(Get_List_Cost() - (Get_List_Cost() * Get_Rebate_Disc(0)/100));
    end;
    Procedure Get_Net_Cost():Decimal
    var
        Disc:Decimal;    
    begin
        Clear(Disc);    
        Disc:= (Get_Rebate_Disc(1) + Get_Rebate_Disc(2) + Get_Rebate_Disc(3))/100;        
        //Exit(Get_List_Cost() - Disc*Get_List_Cost());
        Exit(Get_First_Costs() - Disc*Get_First_Costs());
    end;
    Procedure Get_Rebate_Disc(RebIndx:integer):Decimal
    var
        reb:record "PC Supplier Brand Rebates"; 
    begin
        Reb.Reset;
        If Rec."Vendor No." <> '' then
            Reb.Setrange("Supplier No.",rec."Vendor No.")
        else
            Reb.Setrange("Supplier No.",Get_Alternate_Vendor);
        Reb.setrange(Brand,rec.Brand);
        Reb.Setrange("Rebate Status",Reb."Rebate Status"::Open);
        If Reb.Findset then
            Case RebIndx of 
                0: Exit(reb."PO Line Disc %");
                1: Exit(reb."Volume Rebate %");
                2: Exit(reb."Marketing Rebate %");
                3: Exit(reb."Supply Chain Rebate %");
            end    
        else
            exit(0);    
    end; 
    Procedure Get_Alternate_Vendor():Code[20]
    var
        ItemVen:record "Item Vendor";
    begin
        ItemVen.Reset;
        ItemVen.setrange("Item No.",rec."No.");
        If ItemVen.FindSet() then
            exit(ItemVen."Vendor No.")
        else
            exit('N/A');    
    end;
    trigger OnBeforeDelete()
    var
        Test:text;
        Sprice:Record "PC Shopfiy Pricing";
        Rel:Record "PC Shopify Item Relations";
        PCost:Record "PC Purchase Pricing";    
    begin
        Test := "No.";
        If Test.Startswith('SKU-') Or Test.StartsWith('PAR-') then
        begin
            If Not Confirm('WARNING deletion is not advised until this item has been properly removed from CRM/Shopify first .. do you still wish to delete now?',False) then
                Error('');
            Sprice.Reset;
            Sprice.Setrange("Item No.","No.");
            If Sprice.findset then Sprice.DeleteAll();
            Pcost.Reset;
            Pcost.Setrange("Item No.","No.");
            If Pcost.findset then Pcost.DeleteAll();
            Rel.Reset;
            if Test.Startswith('SKU-') then
                rel.Setrange("Child Item No.","no.")
            else
                rel.Setrange("Parent Item No.","No.");
            If Rel.findset then Rel.DeleteAll();
        end;            
    end;

}