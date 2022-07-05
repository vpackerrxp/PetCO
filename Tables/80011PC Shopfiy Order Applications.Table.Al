table 80011 "PC Shopfiy Order Applications"
{
    DataClassification = ToBeClassified;
    
    fields
    {
        field(10;ID; BigInteger)
        {
            AutoIncrement = True;
            Editable = false;
        }
        field(20;"ShopifyID"; BigInteger)
        {}
        field(30;"Shopify Order ID"; BigInteger)
        {}
        field(40;"Shopify App Type";text[30])
        {
            trigger OnValidate()
            begin
                Case"Shopify App Type".ToUpper() of
                    'MANUAL': "Shopify Application Type" := "Shopify Application Type"::manual;    
                    'SCRIPT': "Shopify Application Type" := "Shopify Application Type"::script;
                    'AUTOMATIC': "Shopify Application Type" := "Shopify Application Type"::automatic;
                    else
                        "Shopify Application Type" := "Shopify Application Type"::discount_code;
                end;            
            end;
        }
        field(50;"Shopify Application Type";Option)
        {
            OptionMembers = manual,automatic,script,discount_code;
        }
        field(55;"Shopify Disc App Code"; Code[100])
        {}
        field(60;"Shopify Disc App Description"; Code[100])
        {}
        field(70;"Shopify Disc App Value";decimal)
        {}
        field(80;"Shopify Disc App Value Type";text[30])
        {}
        field(90;"Shopify Disc App Index"; Integer)
        {}
    }
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
    trigger OnModify()
    var
        DiscApp:Record "PC Shopify Disc Apps";
    begin
        if Not DiscApp.get("Shopify Application Type","Shopify Disc App Code","Shopify Disc App Value") then
        begin
            DiscApp.Init;
            DiscApp."Shopify Discount App Type" := "Shopify Application Type";
            DiscApp."Shopify Disc App Code" := "Shopify Disc App Code";
            If "Shopify Disc App Description" <> '' then
                DiscApp."Shopify Disc App Description" := "Shopify Disc App Description"
            else
                DiscApp."Shopify Disc App Description" := Strsubstno('Discount Value @ %1 %',"Shopify Disc App Value");
            DiscApp."Shopify Value" := "Shopify Disc App Value";
            DiscApp."Shopify Value Type" := "Shopify Disc App Value Type";
            DiscApp."Shopify App ID" := ID;
            DiscApp.insert;
        end;
    end;
}