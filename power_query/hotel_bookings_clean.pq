let
    Source = hotel_bookings_raw,
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Trimmed Text" = Table.TransformColumns(#"Promoted Headers",{{"hotel", Text.Trim, type text}, {"is_canceled", Text.Trim, type text}, {"lead_time", Text.Trim, type text}, {"arrival_date_year", Text.Trim, type text}, {"arrival_date_month", Text.Trim, type text}, {"arrival_date_week_number", Text.Trim, type text}, {"arrival_date_day_of_month", Text.Trim, type text}, {"stays_in_weekend_nights", Text.Trim, type text}, {"stays_in_week_nights", Text.Trim, type text}, {"adults", Text.Trim, type text}, {"children", Text.Trim, type text}, {"babies", Text.Trim, type text}, {"meal", Text.Trim, type text}, {"country", Text.Trim, type text}, {"market_segment", Text.Trim, type text}, {"distribution_channel", Text.Trim, type text}, {"is_repeated_guest", Text.Trim, type text}, {"previous_cancellations", Text.Trim, type text}, {"previous_bookings_not_canceled", Text.Trim, type text}, {"reserved_room_type", Text.Trim, type text}, {"assigned_room_type", Text.Trim, type text}, {"booking_changes", Text.Trim, type text}, {"deposit_type", Text.Trim, type text}, {"agent", Text.Trim, type text}, {"company", Text.Trim, type text}, {"days_in_waiting_list", Text.Trim, type text}, {"customer_type", Text.Trim, type text}, {"adr", Text.Trim, type text}, {"required_car_parking_spaces", Text.Trim, type text}, {"total_of_special_requests", Text.Trim, type text}, {"reservation_status", Text.Trim, type text}, {"reservation_status_date", Text.Trim, type text}}),
    #"Cleaned Text" = Table.TransformColumns(#"Trimmed Text",{{"hotel", Text.Clean, type text}, {"is_canceled", Text.Clean, type text}, {"lead_time", Text.Clean, type text}, {"arrival_date_year", Text.Clean, type text}, {"arrival_date_month", Text.Clean, type text}, {"arrival_date_week_number", Text.Clean, type text}, {"arrival_date_day_of_month", Text.Clean, type text}, {"stays_in_weekend_nights", Text.Clean, type text}, {"stays_in_week_nights", Text.Clean, type text}, {"adults", Text.Clean, type text}, {"children", Text.Clean, type text}, {"babies", Text.Clean, type text}, {"meal", Text.Clean, type text}, {"country", Text.Clean, type text}, {"market_segment", Text.Clean, type text}, {"distribution_channel", Text.Clean, type text}, {"is_repeated_guest", Text.Clean, type text}, {"previous_cancellations", Text.Clean, type text}, {"previous_bookings_not_canceled", Text.Clean, type text}, {"reserved_room_type", Text.Clean, type text}, {"assigned_room_type", Text.Clean, type text}, {"booking_changes", Text.Clean, type text}, {"deposit_type", Text.Clean, type text}, {"agent", Text.Clean, type text}, {"company", Text.Clean, type text}, {"days_in_waiting_list", Text.Clean, type text}, {"customer_type", Text.Clean, type text}, {"adr", Text.Clean, type text}, {"required_car_parking_spaces", Text.Clean, type text}, {"total_of_special_requests", Text.Clean, type text}, {"reservation_status", Text.Clean, type text}, {"reservation_status_date", Text.Clean, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Cleaned Text"),
    // Removed columns = [arrival_date_week_number, company, reservation_status].
    #"Removed Columns" = Table.RemoveColumns(#"Removed Duplicates",{"arrival_date_week_number", "company", "reservation_status_date"}),
    // Merged columns = [arrival_date_year, arrival_date_month, arrival_date_day_of_month] into one column [arrival_date].
    // 
    #"Merged Columns" = Table.CombineColumns(#"Removed Columns",{"arrival_date_year", "arrival_date_month", "arrival_date_day_of_month"},Combiner.CombineTextByDelimiter("-", QuoteStyle.None),"arrival_date"),
    // Replaced "NA" values with (0) in [children] column.
    #"Replaced Value" = Table.ReplaceValue(#"Merged Columns","NA","0",Replacer.ReplaceValue,{"children"}),
    // Replaced "Undefined" values with "SC" in [meal] column.
    #"Replaced Value1" = Table.ReplaceValue(#"Replaced Value","Undefined","SC",Replacer.ReplaceValue,{"meal"}),
    // Replaced "NULL" values with "Unknown" in [country] column.
    #"Replaced Value2" = Table.ReplaceValue(#"Replaced Value1","NULL","Unknown",Replacer.ReplaceValue,{"country"}),
    // Replaced "NULL" values with "No-Agent" in [agent] column.
    #"Replaced Value3" = Table.ReplaceValue(#"Replaced Value2","NULL","No-Agent",Replacer.ReplaceValue,{"agent"}),
    // # Changed Dtypes = [[is_canceled], [lead_time], [stays_in_weekend_nights], [adults], [children], [babies], [is_repeated_guest], [previous_cancellations], [previous_bookings_not_canceled], [booking_changes], [days_in_waiting_list], [required_car_parking_spaces], [total_of_special_requests]] to Whole number type.
    // ### [adr] to Decimal type.
    // ### [arrival_date] to Date type.
    // 
    #"Changed Type" = Table.TransformColumnTypes(#"Replaced Value3",{{"is_canceled", Int64.Type}, {"lead_time", Int64.Type}, {"stays_in_weekend_nights", Int64.Type}, {"stays_in_week_nights", Int64.Type}, {"adults", Int64.Type}, {"children", Int64.Type}, {"babies", Int64.Type}, {"is_repeated_guest", Int64.Type}, {"previous_cancellations", Int64.Type}, {"previous_bookings_not_canceled", Int64.Type}, {"days_in_waiting_list", Int64.Type}, {"required_car_parking_spaces", Int64.Type}, {"total_of_special_requests", Int64.Type}, {"adr", type number}, {"booking_changes", Int64.Type}, {"arrival_date", type date}}),
    // Added a column [total_guests] = [adults] + [children] + [babies].
    #"Added Custom" = Table.AddColumn(#"Changed Type", "total_guest", each [adults]+[children]+[babies]),
    // Added a column [total_nights] = [stays_in_week_nights] + [stays_in_weekend_nights].
    // 
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "total_nights", each [stays_in_weekend_nights]+[stays_in_week_nights]),
    // Added a column [revenue] = [total_nights] * [adr].
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "revenue", each [total_nights] * [adr]),
    // Added a column [lead_time_bucket] which splits [lead_time] into seperate ranges for better interpretation and visualization in later stages.
    #"Added Custom3" = Table.AddColumn(#"Added Custom2", "lead_time_bucket", each if [lead_time] <= 7 then "1. 0-7 days"
else if [lead_time] <= 30 then "2. 8-30 days"
else if [lead_time] <= 90 then "3. 31-90 days"
else if [lead_time] <= 180 then "4. 91-180 days"
else "5. 180+ days"),
    // Changed Dtypes of the new custom columns to their appropriate types.
    // 
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom3",{{"lead_time_bucket", type text}, {"total_guest", Int64.Type}, {"total_nights", Int64.Type}, {"revenue", type number}}),
    // Filtered out rows with [total_guests] = 0.
    // Filtered out rows with "Undefined" in [market_segment] and [distribution channel] columns because there is no way to know their true values.
    #"Filtered Rows" = Table.SelectRows(#"Changed Type1", each ([market_segment] <> "Undefined") and ([total_guest] <> 0) and ([distribution_channel] <> "Undefined")),
    // Filtered out (1) row with [adr] < 0
    #"Filtered Rows1" = Table.SelectRows(#"Filtered Rows", each [adr] >= 0),
    // Simple Reordering of columns.
    #"Reordered Columns" = Table.ReorderColumns(#"Filtered Rows1",{"hotel", "is_canceled", "lead_time", "lead_time_bucket", "arrival_date", "stays_in_weekend_nights", "stays_in_week_nights", "total_nights", "adults", "children", "babies", "total_guest", "meal", "country", "market_segment", "distribution_channel", "is_repeated_guest", "previous_cancellations", "previous_bookings_not_canceled", "reserved_room_type", "assigned_room_type", "booking_changes", "deposit_type", "agent", "days_in_waiting_list", "customer_type", "adr", "revenue", "required_car_parking_spaces", "total_of_special_requests", "reservation_status"}),
    // Final formatting, fixing typos.
    #"Renamed Columns" = Table.RenameColumns(#"Reordered Columns",{{"is_canceled", "is_cancelled"}, {"total_guest", "total_guests"}, {"previous_bookings_not_canceled", "previous_bookings_not_cancelled"}})
in
    #"Renamed Columns"
