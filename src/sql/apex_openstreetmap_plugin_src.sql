function render_osm_map (
    p_region              in apex_plugin.t_region,
    p_plugin              in apex_plugin.t_plugin,
    p_is_printer_friendly in boolean )
    return apex_plugin.t_region_render_result
is
    -- variables
    map_data_markers apex_plugin_util.t_column_value_list;
    map_data_polygons apex_plugin_util.t_column_value_list;
    query_markers varchar2(400) :=	'''{"''||src_loc_type||''": [''||replace(src_lat, '','', ''.'')||'', ''||replace(src_lng, '','', ''.'')||''], "color": "''||src_color||''", "text": "''||src_label||''", "address": "''||replace(src_address, ''"'', '' '')||''"},''';
    query_polygons varchar2(400) :=	'''{"''||src_loc_type||''": [''||src_loc_type||''], "color": "''||src_color||''", "text": "''||src_label||''"},''';
    x number;
    
    -- attributes
    height varchar2(10) := nvl(p_region.attribute_01, '700px');
    center varchar2(100) := nvl(p_region.attribute_03, 'lat, lng');
    zoom varchar2(100) := nvl(p_region.attribute_04, '14');
    max_zoom varchar2(100) := nvl(p_region.attribute_05, '18');
    source varchar2(400) := nvl(p_region.attribute_02, 'select marker_type as src_marker_type, loc_type as src_loc_type, lat as src_lat, lng as src_lng, loc as src_loc, color as src_color, label as src_label from src_table');
        
begin
    apex_javascript.add_library (
        p_name      => 'map',
        p_directory => p_plugin.file_prefix || 'assets/js/',
        p_version   => NULL
    );

    map_data_markers := APEX_PLUGIN_UTIL.GET_DATA (
        p_sql_statement    => 'select '||query_markers||' as results from ('||source||' where marker_type = ''markers'' and lat is not null)',
        p_min_columns      => 1,
        p_max_columns      => 1,
        p_component_name   => p_region.name,
        p_search_type      => NULL,
        p_search_column_no => NULL,
        p_search_string    => NULL,
        p_first_row        => NULL,
        p_max_rows         => NULL
    );
    map_data_polygons := APEX_PLUGIN_UTIL.GET_DATA (
        p_sql_statement    => 'select '||query_polygons||' as results from ('||source||' where marker_type = ''polygons'')',
        p_min_columns      => 1,
        p_max_columns      => 1,
        p_component_name   => p_region.name,
        p_search_type      => NULL,
        p_search_column_no => NULL,
        p_search_string    => NULL,
        p_first_row        => NULL,
        p_max_rows         => NULL
    );
    htp.p('
        <div id="mapid" style="width: 100%; height: ' || height || ';"></div>
        <script>       

                function onMapClick(e) {
                    $x("P7_LAT").value = e.latlng.lat;
                    $x("P7_LON").value = e.latlng.lng;
                }  
          
            function renderMap() {
                var mymap = L.map("mapid").setView(['||center||'], '||zoom||');
                L.tileLayer("https://{s}.tile.osm.org/{z}/{x}/{y}.png", {maxZoom: '||max_zoom||'}).addTo(mymap);
                mymap.on("click", onMapClick);
                updateMap(mymap, ' || '{markers:[');
                
    FOR x in 1 .. map_data_markers(1).count LOOP
        htp.p(map_data_markers(1)(x));
    end loop;
    
    htp.p('],polygons:[');
    FOR y in 1 .. map_data_polygons(1).count LOOP
        htp.p(map_data_polygons(1)(y));
    end loop;
    
    htp.p(']}, "' || p_plugin.file_prefix || '");
            };

        </script>
    ');

    apex_javascript.add_onload_code('renderMap()');
    return null;
end;
