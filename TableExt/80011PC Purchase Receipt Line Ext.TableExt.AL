
tableextension 80011 "PC Purchase Receipt Line Ext" extends "Purch. Rcpt. Line"
{
    fields
    {
        field(80000; "Line Rebate %"; Decimal)
        {
            editable = false;
        }
        field(80001; "Fulfilo Recvd Qty"; Decimal)
        {
            editable = false;
        }
        field(80002; "Original Order Qty"; Decimal)
        {
            editable = false;
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
    trigger OnAfterInsert()
    begin
        Add_Brand_Rebate_Supplier();
    end;
    trigger OnAfterModify()
    begin
        Add_Brand_Rebate_Supplier();
    end;
    Local procedure Add_Brand_Rebate_Supplier()
    var
        Item:Record Item;
        SuppBrand:Record "PC Supplier Brand Rebates";
    begin
        If Rec.Type = Rec.type::Item then
        begin
            If Item.get("No.") then
            begin
                Rec.Brand := Item.Brand;
                SuppBrand.Reset;
                SuppBrand.SetRange(Brand,Rec.Brand);
                If SuppBrand.FindSet() then
                    rec."Rebate Supplier No." := SuppBrand."Rebate Supplier No.";
            end;        
        end;
    end;    
}