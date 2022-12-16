tableextension 80009 "PC Purchase Line Ext" extends "Purchase Line"
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                Cuf:Codeunit "PC Fulfilio Routines";
                Cu:Codeunit "PC Import Export Routines";
                Item:Record Item;
                ItemUnit:record "Item Unit of Measure";
                SupReb:record "PC Supplier Brand Rebates";
            begin
                Cuf.Purch_Rebates(rec);
                If Rec.Type = Rec.Type::Item then
                begin
                    Item.Get("No.");       
                    If ItemUnit.get(Rec."No.",Rec."Unit of Measure Code") then
                        Rec.validate("Direct Unit Cost",Cu.Get_Cost(Item,Rec."Buy-from Vendor No.") * ItemUnit."Qty. per Unit of Measure");   
                end;
            end;    
        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            var
                Cu:Codeunit "PC Import Export Routines";
                Item:Record Item;
                ItemUnit:record "Item Unit of Measure";
            begin
                If "Fulfilo Recvd Qty" = -1 then
                begin 
                    "Original Order Qty" := Quantity;
                    "Original Order Qty(Base)" := "Quantity (Base)";
                end;
                If Rec.Type = Rec.Type::Item then
                begin
                    Item.Get("No.");       
                    If ItemUnit.get(Rec."No.",Rec."Unit of Measure Code") then
                        Rec.validate("Direct Unit Cost",Cu.Get_Cost(Item,Rec."Buy-from Vendor No.") * ItemUnit."Qty. per Unit of Measure");   
                end;
            end;                
        }
        modify("Unit of Measure Code")
        {
            trigger OnAfterValidate()
            var
                Cu:Codeunit "PC Import Export Routines";
                Item:Record Item;
                ItemUnit:record "Item Unit of Measure";
            begin
                If "Fulfilo Recvd Qty" = -1 then "Original Order UOM" := "Unit of Measure Code";
                If Rec.Type = Rec.Type::Item then
                begin
                    Item.Get("No.");       
                    If ItemUnit.get(Rec."No.",Rec."Unit of Measure Code") then
                        Rec.validate("Direct Unit Cost",Cu.Get_Cost(Item,Rec."Buy-from Vendor No.") * ItemUnit."Qty. per Unit of Measure");   
                end;
            end;                
        }
       field(80000; "Line Rebate %"; Decimal)
        {
            editable = false;
        }
        field(80001; "Fulfilo Recvd Qty"; Decimal)
        {
            InitValue = -1;
           // editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(80002; "Original Order Qty"; Decimal)
        {
            editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(80003; "Original Order Qty(Base)"; Decimal)
        {
            editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(80004; "Original Order UOM"; Code[10])
        {
            editable = false;
        }
       field(80005;"Brand"; Code[30])
        {
            editable = false;
        }
        field(80006;"Rebate Supplier No."; Code[20])
        {
            editable = false;
        }
    }
}



