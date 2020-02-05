 /***
* Name: SteinwerderSud (SWS)
* Author: lopezbaeza
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWS

global {
	string cityGISFolder <- "/external/";
	string Scenario <- "/external/Scenario1/"; int scenario;
	file site_plan <- image_file(cityGISFolder + "Site Plan.png");
	file boundary <- file(cityGISFolder + "bounds.shp");
	
	file road_traffic <- shape_file(Scenario + "roads-detail-multiline.shp");//-multiline.shp");
	//file railway_traffic <- shape_file(Scenario + "railways.shp");
	//file waterway_traffic <- shape_file(Scenario + "waterways.shp");
	file shape_landfill <- shape_file(Scenario + "landfill.shp");
	file traffic_counters_file <- file(Scenario + "traffic_counters.shp");
	file shapefile_traffic_lights <- file(Scenario + "Traffic Lights.shp");
	file shape_sand_sources<- file(Scenario + "sand_sources.shp");
	//file shape_shoreline<-file(Scenario + "shoreline.shp");
	
	csv_file traffic_counts_file <- csv_file((Scenario + "_2019_09_Neuhof_5min-v3-oneDAY.csv"),true);//-v3-oneDAY.csv"),true);
	csv_file traffic_lights_schedules <- csv_file((Scenario + "_traffic_lights.csv"),true);
	
	geometry shape <- envelope(boundary) + 100.0;
	float cycle_equals<-1.0; //in seconds
	float step <- cycle_equals#s; //simulation speed
	
	int adaptative_speed_factor;
	int truck_capacity; float truck_frequency; float inv_truck_frequency; int time_horizon; int boat_proportion;
	
	map<road,float> road_weights;
	graph road_network; //graph waterway_network; graph railway_network;
	
	/////////User interaction starts here
	list<sand_sources> moved_agents ;
	point target;
	geometry zone <- circle(20);
	bool can_drop;

	action kill {
		ask moved_agents{
			do die;
		}
		moved_agents <- list<sand_sources>([]);
	}

	action duplicate {
		geometry available_space <- (zone at_location target) - (union(moved_agents) + 10);
		create sand_sources number: length(moved_agents) with: (location: any_location_in(available_space));
	}
	int count <- 0; //////////////////////double click modification test starts here
	float z <- 0.0;
	action click {
				if (count > 1 and machine_time - z > 200) {
			count <- 0;
			return;
		}
		if (count < 1) {
			count <- count + 1;
			z <- machine_time;
			return;
		}
		if(machine_time-z>200){ 
			z <- machine_time;
			return;
		} 
		count <- 0; //////////////////////double click modification test ends here
		if (empty(moved_agents)){
			list<sand_sources> selected_agents <- sand_sources inside (zone at_location #user_location);
			moved_agents <- selected_agents;
			ask selected_agents{
				difference <- #user_location - location;
			}
		} else if (can_drop){
			ask moved_agents{
			}
			moved_agents <- list<sand_sources>([]);
		}
	}

	action move {
		can_drop <- true;
		target <- #user_location;
		list<sand_sources> other_agents <- (sand_sources inside (zone at_location #user_location)) - moved_agents;
		geometry occupied <- geometry(other_agents);
		ask moved_agents{
			location <- #user_location - difference;
			if (occupied intersects self){
				can_drop <- false;
			} else{
			}
		}
	}
////////////User interaction ends here
	
	int current_hour;int current_day <- 1;int current_minute; string time_info;
	reflex time_update when: every(1#mn) {
		current_minute <- current_minute +1;
		if current_minute > 59{current_minute <- 0; current_hour <- current_hour+1;}
		if current_hour > 23{current_hour <- 0; current_day <- current_day+1;} 
		if current_minute>9{time_info <- "Day: " + string (current_day) + " Hour: " + string(current_hour) + ":"+string(current_minute);}
		else {time_info <- "Day: " + string (current_day) + " Hour: " + string(current_hour) + ":0"+string(current_minute);}
		}
	
	string timestamp;int DG15; int DG16; int DG22; int DG23; int DG24; int DG25; int DG26; int DG77; int DG78; int DG79; int DG80; int DG81; int WIM11; int WIM12; int WIM21; int WIM22;
	int DG22_lkw; int DG23_lkw; int DG24_lkw; int DG25_lkw;
	
	reflex count when: every(1#mn){
		DG22<-traffic_counters where (each.name='DG22') sum_of(each.npkw);
		DG23<-traffic_counters where (each.name='DG23') sum_of(each.npkw);
		DG22_lkw<-traffic_counters where (each.name='DG22') sum_of(each.nlkw);
		DG23_lkw<-traffic_counters where (each.name='DG23') sum_of(each.nlkw);
		
		DG24<-traffic_counters where (each.name='DG24') sum_of(each.npkw);
		DG25<-traffic_counters where (each.name='DG25') sum_of(each.npkw);
		DG24_lkw<-traffic_counters where (each.name='DG24') sum_of(each.nlkw);
		DG25_lkw<-traffic_counters where (each.name='DG25') sum_of(each.nlkw);
	}
	
	/*reflex export_csv when: every(5#mn){
		timestamp <- string(current_hour) + ":"+string(current_minute)+":00";
		DG15<-traffic_counters where (each.name='DG15') sum_of(each.npkw);
		DG16<-traffic_counters where (each.name='DG16') sum_of(each.npkw);
		DG22<-traffic_counters where (each.name='DG22') sum_of(each.npkw);
		DG23<-traffic_counters where (each.name='DG23') sum_of(each.npkw);
		DG24<-traffic_counters where (each.name='DG24') sum_of(each.npkw);
		DG25<-traffic_counters where (each.name='DG25') sum_of(each.npkw);
		DG26<-traffic_counters where (each.name='DG26') sum_of(each.npkw);
		DG77<-traffic_counters where (each.name='DG77') sum_of(each.npkw);
		DG78<-traffic_counters where (each.name='DG78') sum_of(each.npkw);
		DG79<-traffic_counters where (each.name='DG79') sum_of(each.npkw);
		DG80<-traffic_counters where (each.name='DG80') sum_of(each.npkw);
		DG81<-traffic_counters where (each.name='DG81') sum_of(each.npkw);
		WIM11<-traffic_counters where (each.name='WIM1.1') sum_of(each.npkw);
		WIM12<-traffic_counters where (each.name='WIM1.2') sum_of(each.npkw);
		WIM21<-traffic_counters where (each.name='WIM2.1') sum_of(each.npkw);
		WIM22<-traffic_counters where (each.name='WIM2.2') sum_of(each.npkw);
		
		save [timestamp,DG15,DG16,DG22,DG23,DG24,DG25,DG26,DG77,DG78,DG79,DG80,DG81,WIM11,WIM12,WIM21,WIM22] to: "../results.csv" type:csv rewrite:false;
	}*/
	int WIM_2;int DG_1516; int DG_78; int DG_26;int WIM_2_lkw;int DG_1516_lkw; int DG_78_lkw; int DG_26_lkw; int from_termin; int from_termin_lkw; //incomming absolute numbers
	int WIM_1; int DG_77; int DG_79; int DG_8081;int WIM_1_lkw; int DG_77_lkw; int DG_79_lkw; int DG_8081_lkw; int to_termin_lkw; int to_termin;//outgoing abosolute numbers
	int DG_22; int DG_23; int DG_22_lkw; int DG_23_lkw; int DG_24; int DG_25; int DG_24_lkw; int DG_25_lkw;
	
	reflex flow_from_file when: every(5#mn){
		//incomming absolute numbers
		WIM_2 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "WIM2") sum_of(each.nb_car));
		DG_1516 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and (each.counter = "DG15" or each.counter = "DG16")) sum_of(each.nb_car));
		DG_78 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG78") sum_of(each.nb_car));
		DG_26 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG26") sum_of(each.nb_car));
		
		WIM_2_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "WIM2") sum_of(each.nb_truck));
		DG_1516_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and (each.counter = "DG15" or each.counter = "DG16")) sum_of(each.nb_truck));
		DG_78_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG78") sum_of(each.nb_truck));
		DG_26_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG26") sum_of(each.nb_truck));
	
		//passing by absolute numbers
		DG_22 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG22") sum_of(each.nb_car));
		DG_23 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG23") sum_of(each.nb_car));
		DG_22_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG22") sum_of(each.nb_truck));
		DG_23_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG23") sum_of(each.nb_truck));
		
		DG_24 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG24") sum_of(each.nb_car));
		DG_25 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG25") sum_of(each.nb_car));
		DG_24_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG24") sum_of(each.nb_truck));
		DG_25_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG25") sum_of(each.nb_truck));
		
		//outgoing abosolute numbers
		WIM_1 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "WIM1") sum_of(each.nb_car));
		DG_77 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG77") sum_of(each.nb_car));
		DG_79 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG79") sum_of(each.nb_car));
		DG_8081 <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and (each.counter = "DG80" or each.counter = "DG81")) sum_of(each.nb_car));
		
		WIM_1_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "WIM1") sum_of(each.nb_truck));
		DG_77_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG77") sum_of(each.nb_truck));
		DG_79_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG79") sum_of(each.nb_truck));
		DG_8081_lkw <- int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and (each.counter = "DG80" or each.counter = "DG81")) sum_of(each.nb_truck));
		
		to_termin<-([(WIM_2+DG_1516+DG_78+DG_26)-(WIM_1+DG_77+DG_79+DG_8081),0] max_of each);
		from_termin<- ([(WIM_1+DG_77+DG_79+DG_8081)-(WIM_2+DG_1516+DG_78+DG_26),0] max_of each);
		to_termin_lkw <- ([(WIM_2_lkw+DG_1516_lkw+DG_78_lkw+DG_26_lkw)-(WIM_1_lkw+DG_77_lkw+DG_79_lkw+DG_8081_lkw),0] max_of each);
		from_termin_lkw <- ([(WIM_1_lkw+DG_77_lkw+DG_79_lkw+DG_8081_lkw)-(WIM_2_lkw+DG_1516_lkw+DG_78_lkw+DG_26_lkw),0] max_of each);
	}
	//Create cars and trucks: amount by cource counter. Destination in proportion to destination counters overall. Terminal records calculated from difference.
	reflex cars_WIM2 when: every((5/[WIM_2,1] max_of each)#mn){create car number:1 with: [location::point(one_of(traffic_counters where (each.name = "WIM2.1" or each.name = "WIM2.2")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "WIM2") mean_of(each.sp_car));
		}}
	reflex trucks_WIM2 when: every((5/[WIM_2_lkw,1] max_of each)#mn){create truck number:1 with: [location::point(one_of(traffic_counters where (each.name = "WIM2.1" or each.name = "WIM2.2")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "WIM2") mean_of(each.sp_truck));
		}}
	reflex cars_DG_1516 when: every((5/[DG_1516,1] max_of each)#mn){create car number:1 with: [location::point(one_of(traffic_counters where (each.name = "DG15" or each.name = "DG16")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and (each.counter = "DG15" or each.counter = "DG16")) mean_of(each.sp_car));
		}}
	reflex trucks_DG_1516 when: every((5/[DG_1516_lkw,1] max_of each)#mn){create truck number:1 with: [location::point(one_of(traffic_counters where (each.name = "DG15" or each.name = "DG16")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and (each.counter = "DG15" or each.counter = "DG16")) mean_of(each.sp_truck));
	}}
	reflex cars_DG78 when: every((5/[DG_78,1] max_of each)#mn){create car number:1 with: [location::point(one_of(traffic_counters where (each.name = "DG78")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG78") mean_of(each.sp_car));
	}}
	reflex trucks_DG78 when: every((5/[DG_78_lkw,1] max_of each)#mn){create truck number:1 with: [location::point(one_of(traffic_counters where (each.name = "DG78")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG78") mean_of(each.sp_truck));
	}}
	reflex cars_DG26 when: every((5/[DG_26,1] max_of each)#mn){create car number:1 with: [location::point(one_of(traffic_counters where (each.name = "DG26")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG26") mean_of(each.sp_car));
	}}
	reflex trucks_DG26 when: every((5/[DG_26_lkw,1] max_of each)#mn){create truck number:1 with: [location::point(one_of(traffic_counters where (each.name = "DG26")))]{
		own_speed<-int(traffic_counts where (each.hour = current_hour and (each.minute = current_minute or each.minute = current_minute+1 or each.minute = current_minute+2 or each.minute = current_minute+3 or each.minute = current_minute+4) and each.day_of_week = current_day and each.counter = "DG26") mean_of(each.sp_truck));
	}}
	reflex cars_from_termin when: every((5/[from_termin,1] max_of each)#mn){create car number:1 with: [location::point(one_of(traffic_counters where (each.name = "from_t")))];}
	reflex trucks_from_termin when: every((5/[from_termin_lkw,1] max_of each)#mn){create truck number:1 with: [location::point(one_of(traffic_counters where (each.name = "from_t")))];}

	reflex update_road_speed{
		road_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
		road_network <- road_network with_weights road_weights;
	}
	
	init{
		create road from:road_traffic with:[road_speed:float(read("maxspeed")),lines:int(read("lines")),avail_dest:string(read("avail_dest"))];
		road_weights <- road as_map (each::each.shape.perimeter);
		road_network <- as_edge_graph(road);
		
		create landfill from:shape_landfill with:[capacity:int(read("capacity")), phase:string(read("type"))];
		create sand_sources from:shape_sand_sources;
		//create shoreline from:shape_shoreline;
		//create waterway from:waterway_traffic; waterway_network <- as_edge_graph(waterway);
		//create railway from:railway_traffic; railway_network <- as_edge_graph(railway);
		create traffic_counters from:traffic_counters_file with:[name:string(read("name"))];
		create traffic_counts from:traffic_counts_file with:[counter:string(read("Spur")), day_of_week:int(read("Day_of_week")),hour:int(read("Hour")),minute:int(read("Minute")),nb_truck:int(read("Lkw")),sp_truck:int(read("Lkw_avgSpeed")),nb_car:int(read("Pkw")),sp_car:int(read("Pkw_avgSpeed"))];
		create traffic_light from:shapefile_traffic_lights  with:[group:string(read("group")),crossing:int(read("crossing"))]; //duration_sequence:int(read("duration_s")),start_green:int(read("start_gree")),end_green:int(read("end_green")),
		create traffic_light_schedule from:traffic_lights_schedules with:[Crossing:int(read("Crossing")), Programme:int(read("Programme")), Group:string(read("Group")), Duration:int(read("Duration")), Start_green:int(read("Start_green")), End_green:int(read("End_green")), Day_of_week:int(read("Day_of_week")), End_hour:int(read("End_hour")), End_minute:int(read("End_minute")), Start_hour:int(read("Start_hour")), Start_minute:int(read("Start_minute"))];
	}
}
//species waterway{}
//species railway{}
//species shoreline{aspect default{draw shape color:#white;}}
species traffic_counts{string counter;int hour; int minute;int sp_car;int nb_car;int sp_truck;int nb_truck;int day_of_week;}
species traffic_counters{
	string name;
	int npkw;
	int nlkw;
	
	reflex restart_counter when: every(5#mn){
		npkw <- 0;
		nlkw <- 0;
	}
}
species traffic_light_schedule{
	int Crossing; int Programme; string Group; int Duration; int Start_green; int End_green; int Day_of_week; int End_hour; int End_minute; int Start_hour; int Start_minute;
	
	reflex active_programm when:current_day=Day_of_week and (current_hour >= Start_hour and current_hour < End_hour) and every(1#mn){
		ask traffic_light where(each.group = self.Group and each.crossing = self.Crossing){
			duration_sequence <- myself.Duration;
			start_green <- myself.Start_green;
			end_green <- myself.End_green;
		}
	}
}
species traffic_light{
	string group; int crossing;
	int duration_sequence; int start_green; int end_green; int t;
	bool is_red;
	
	reflex sequences when:every(1#s){
		t<-t+1; if t>duration_sequence{t<-0;}
		if start_green<end_green{
			if t >=start_green and t<end_green{is_red<-false;}else{is_red<-true;}}
		if start_green>end_green {
			if (t>end_green and t>=start_green) or (t<end_green and t<=start_green){is_red<-false;}else{is_red<-true;}}
		}
	aspect default {if is_red {color<-#red;}else {color<-#green;} draw circle(3) color:color;}
}

species road{
	string avail_dest;
	float capacity <- 1+(shape.perimeter*lines)/adaptative_speed_factor; // This factor relates the number of cars per segment and the speed of them
	int number_of_cars <- 0 update: length(car at_distance 1)+ length(truck at_distance 1);
	float speed_coeff <- 1.0 update:  exp(-number_of_cars/capacity) min: 0.1;
	int lines;
	float road_speed;
	int color <- 1 update: int(1+(number_of_cars*5000)/shape.perimeter);

	float vmax<-road_speed;
	float vmin<- 0.0 update: [(car at_distance 1) min_of each.real_speed,0.01]max_of each;
	float vmean<-0.0 update: [(car at_distance 1) mean_of each.real_speed,0.01]max_of each;
	
	int flow; int flow_now; float density; float speed_drop;float time_delay;
	reflex restart_calculation when: every(1#mn){flow_now<-0;}
	reflex calculate_congestion_criteria{
		//calculation of flow every minute in car/min
		if flow_now<number_of_cars{flow_now<-number_of_cars;}
		flow<-flow_now*60;
		//calculation of density every minute in car/m
		density<-number_of_cars/self.shape.perimeter;
		//calulation of speed drop compared to max speed permitted in %
		speed_drop<-100*vmin/vmax;
		//calculation of time delay in seconds
		time_delay<-3600/((self.shape.perimeter/1000)*[(vmax-vmin),0.1]max_of each);
	}
	
	bool over_capacity; bool over_congestion;
	reflex evaluate_congestion{
		if flow<11000 {over_capacity<-false;over_congestion<-false;}
		if flow>=1100 and flow<1900{over_capacity<-true;over_congestion<-false;}
		if flow>=1900{over_capacity<-false;over_congestion<-true;}
		if density<0.018 {over_capacity<-false;over_congestion<-false;}
		if density>=0.018 and flow<0.143{over_capacity<-true;over_congestion<-false;}
		if density>=0.143{over_capacity<-false;over_congestion<-true;}
	}
	
	aspect default {
		draw (shape) color: rgb(40+color,50+color,60+color);
		if over_capacity and not over_congestion {draw "Flow:"+string(flow)+"veh/h Density:"+string(density)+"veh/m Speed Drop:"+string(speed_drop)+"% Delay:"+string(time_delay)+"s" color:#gray font:font("Helvetica", 8, #plain);}
		else if not over_capacity and over_congestion{draw "Flow:"+string(flow)+"veh/h Density:"+string(density)+"veh/m Speed Drop:"+string(speed_drop)+"% Delay:"+string(time_delay)+"s" color:#red font:font("Helvetica", 8, #plain);}
	}
}
species car skills: [moving] control:fsm{
	float rd_speed <- 15#km/#h update: (road closest_to self).road_speed;
	int own_speed;
	int new_speed;
	traffic_counters final_target;
	rgb color;
	int angle<-10; //enough to cover one line only
	bool waiting; //if it's first in line to traffic light
	bool waiting_behind; //the vehicle before is waiting
	point old_location;
	int n<-2; //adaptation factor for detection of things (see further)
	int stop_distance<-10;
	
	reflex target_choice when: final_target = nil{
		int choice_taken<-rnd(WIM_1+DG_77+DG_79+DG_8081+to_termin); //choice from 0-100%
		if choice_taken <= WIM_1{final_target<-(one_of(traffic_counters where (each.name = "WIM1.1" or each.name = "WIM1.2")));}
		else if choice_taken > WIM_1 and choice_taken <= (WIM_1+DG_77){final_target<-(one_of(traffic_counters where (each.name = "DG77")));}
		else if choice_taken > (WIM_1+DG_77) and choice_taken <= (WIM_1+DG_77+DG_79){final_target<-(one_of(traffic_counters where (each.name = "DG79")));}
		else if choice_taken > (WIM_1+DG_77+DG_79) and choice_taken <= (WIM_1+DG_77+DG_79+DG_8081){final_target<-(one_of(traffic_counters where (each.name = "DG80" or each.name = "DG81")));}
		else if choice_taken > (WIM_1+DG_77+DG_79+DG_8081){final_target<-(one_of(traffic_counters where (each.name = "termin")));}
	}
	
	reflex clean when:every(2#mn){
		if location = old_location{do die;}
		old_location <- location;
	}

	reflex go_to_destination when: not waiting and not waiting_behind{
		do goto target:final_target.location on: road_network  recompute_path: false  move_weights:road_weights speed:mean(new_speed,rd_speed);
		if location distance_to final_target < 20 {do die;}
		if real_speed =0 {do die;} // Eliminates cars that are not able to trace a destination
		if own_speed =0 {own_speed<- int(rd_speed);}
	}
	
	list<traffic_counters> counted_by_counter_control; //control variable to make traffics count car only once
	reflex avoid_others {
		color<-#white;
		waiting_behind<-false;
		new_speed<-own_speed+1;
		list<car> nearby_cars <- car inside geometry(cone(heading-angle,heading+angle) intersection circle(stop_distance));
		list<truck> nearby_trucks <- truck inside geometry(cone(heading-angle,heading+angle) intersection circle(stop_distance));
		list<traffic_counters> counted_by_counter <- traffic_counters inside geometry(cone(heading-angle,heading+angle) intersection circle(15));
	
		if not empty(counted_by_counter) and not empty (counted_by_counter-counted_by_counter_control) {
			loop obs over: (counted_by_counter){
				if self is truck{(counted_by_counter closest_to self).nlkw <- (counted_by_counter closest_to self).nlkw + 1;}
				else {(counted_by_counter closest_to self).npkw <- (counted_by_counter closest_to self).npkw + 1;}
				}
			}
		counted_by_counter_control <- traffic_counters inside geometry(cone(heading-angle,heading+angle) intersection circle(15));
		
		//Adapts speed to vehicle before him
		if not empty(nearby_cars+nearby_trucks-self) {
			loop obs over: (nearby_cars+nearby_trucks-self){
				new_speed <- int(((nearby_cars+nearby_trucks-self) closest_to self).real_speed)-5; //makes the car go 5km/h slower than the car in the front
	
		//Avoid counterdirection
				if abs((((nearby_cars+nearby_trucks-self) closest_to self).heading)-self.heading) > 180 {do die;}
				
		//Stops if car before is stopped
				if ((nearby_cars+nearby_trucks-self) closest_to self).waiting or ((nearby_cars+nearby_trucks-self) closest_to self).waiting_behind{
					waiting_behind<-true;	
				}
				color<-#gray;}}
	}
	
	reflex stop_ampel{ //Stops in traffic light
		waiting<-false;
		list<traffic_light> nearby_ampel <- traffic_light inside geometry(cone(heading-angle*n,heading+angle*n) intersection circle(10));
		if not empty(nearby_ampel) { loop obs over: (nearby_ampel){ if (nearby_ampel closest_to self).is_red {waiting<-true;color<-#gray;}}}	
		}
	
	aspect default {
		draw rectangle(6,3) color:color rotate:heading;
		//draw geometry(cone(heading-angle,heading+angle) intersection circle(15)) color: color;
	}
}
species truck parent:car{
	int stop_distance<-15;
	reflex target_choice when: final_target = nil{
		int choice_taken<-rnd(WIM_1_lkw+DG_77_lkw+DG_79_lkw+DG_8081_lkw+to_termin_lkw); //choice from 0-1
		if choice_taken <= WIM_1_lkw{final_target<-(one_of(traffic_counters where (each.name = "WIM1.1" or each.name = "WIM1.2")));}
		else if choice_taken > WIM_1_lkw and choice_taken <= (WIM_1_lkw+DG_77_lkw){final_target<-(one_of(traffic_counters where (each.name = "DG77")));}
		else if choice_taken > (WIM_1_lkw+DG_77_lkw) and choice_taken <= (WIM_1_lkw+DG_77_lkw+DG_79_lkw){final_target<-(one_of(traffic_counters where (each.name = "DG79")));}
		else if choice_taken > (WIM_1_lkw+DG_77_lkw+DG_79_lkw) and choice_taken <= (WIM_1_lkw+DG_77_lkw+DG_79_lkw+DG_8081_lkw){final_target<-(one_of(traffic_counters where (each.name = "DG80" or each.name = "DG81")));}
		else if choice_taken > (WIM_1_lkw+DG_77_lkw+DG_79_lkw+DG_8081_lkw){final_target<-(one_of(traffic_counters where (each.name = "termin")));}
	}
	aspect default {
		draw rectangle(12,3) color:color rotate:heading;
		//draw circle(6) empty:true width: 0.1 color:#grey;
		//draw geometry(cone(heading-angle,heading+angle) intersection circle(15)) color: color;
	}
}
species sand_truck parent:car{
	int capacity <- truck_capacity;
	traffic_counters final_target<-(one_of(traffic_counters where (each.name = "termin")));
	
	reflex go_to_destination when: not waiting and not waiting_behind{
		do goto target:final_target.location on: road_network  recompute_path: false  move_weights:road_weights speed:mean(new_speed,rd_speed);
		if location distance_to final_target < 20 {
			if capacity>1{ //when they arrive full to the storege/landfill
				create sand number:1 with: [location::self.location]{capacity<-myself.capacity;}
				final_target<-(one_of(traffic_counters where (each.name = "DG81")));
				create sand_truck number:1 with: [location::point(one_of(traffic_counters where (each.name = "from_t")))]{capacity<-0; final_target<-(one_of(traffic_counters where (each.name = "DG81")));}
				do die;
			}else{do die;} //when they arrive empty to the final exit location
		}
		if real_speed =0 {do die;} // Eliminates cars that are not able to trace a destination
		if own_speed =0 {own_speed<- int(rd_speed);}
	}
	
	aspect default {
		draw rectangle(12,3) color:color rotate:heading;
		draw circle(20) empty:true width: 0.1 color:color;
	}
}

species sand_sources{
	bool active<-true;
	int capacity;
	float carried_by_boat<-capacity*(boat_proportion/100);
	float carried_by_truck<-capacity-carried_by_boat;
	rgb color;
	reflex create_sand_trucks when: active and scenario>1 and every (inv_truck_frequency*length(sand_sources where each.active) #mn){
		create sand_truck number:1 with: [location::location];carried_by_truck<-carried_by_truck-truck_capacity;
		if carried_by_truck<1{active<-false;}
		ask landfill where each.active_phase{filled<-int((filled+(myself.carried_by_boat))/length(landfill where each.active_phase));}
	}
	reflex update_color when: every(1#mn){if active{color<-#white;}else{color<-#gray;}}
////////////User interaction starts here
	point difference <- { 0, 0 };
	reflex r {
		if (!(moved_agents contains self)){}
	}
////////////User interaction ends here
	aspect default {draw circle(5) color:color;}
}

species sand skills:[moving]{
	int capacity;
	landfill final_target<-(one_of(landfill where (each.active_phase)));
	
	reflex go_to_destination {
		do goto target:final_target.location speed:50.0;
		if location distance_to final_target < 5 {ask final_target{filled <- filled + myself.capacity;} do die;}}
	
	aspect default {
		draw circle(8) empty:true width: 0.1 color:#yellow;
		draw circle(2) color:#yellow;
		draw string(capacity);}
}

species landfill{
	int capacity; int filled; int remaining<- 0 update: (capacity-filled); float complete <- 0.0 update: (filled/capacity);
	string phase;
	bool active_phase;
	
	reflex update_phase when: every(1#h){
		if scenario = 1 and phase="ausbau" and complete <1 {active_phase<-true; filled<-capacity;}
		else if scenario = 2 and phase="storage" and complete <1 {active_phase<-true; filled<-330000;}
		else if scenario = 3 and phase="einbau" and complete <1 {active_phase<-true; filled<-991000;}
		else {active_phase<-false;}
	}
	
	reflex update_truck_fequency when:active_phase {
		truck_frequency<- ((capacity-filled)/truck_capacity) / (time_horizon*20*8*60); // number of trucks needed/time horizon to fullfill (8hours/day, 20days/month)
		if truck_frequency=0{inv_truck_frequency<-0.0;}else{inv_truck_frequency<-(1/truck_frequency);} //number of trucks per minute converted in one truck every n minutes
	}
	
	aspect default{
		if active_phase{draw shape empty:true color:#gray; draw string(round(complete*100))+"%" color:#white;}
	}
}


experiment SWS type: gui {
	parameter "Scenario (1.ausbau; 2.storage, 3.einbau)" var: scenario init:1 min:1 max:3 category: "Set up";
	parameter "Truck capacity (m3)" var: truck_capacity init:90 min:1 max:200 category: "Set up";
	parameter "Time horizon of phase (months)" var: time_horizon init:12 min:1 max:36 category: "Set up";
	parameter "% of Boat usage" var: boat_proportion init:0 min:0 max:100 category: "Set up";
	parameter "Simulation Speed" var:cycle_equals init:0.25 min:0.05 max:2.0 category:"Calibrating";
	parameter "Starting Hour" var:current_hour init:12 min:0 max:23 category:"Calibrating";
	parameter "Speed Variation" var: adaptative_speed_factor init:10 min:1 max:100 category:"Calibrating";
	output {
		layout #split;
		display charts  background: rgb(55,62,70) refresh:every(1#s) camera_interaction:false{
			chart "Incoming Traffic" type: series size:{1,0.2} position: {0,0} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Cars in model" value: length(car) color: rgb(242, 141, 186) marker_size:0 thickness:1.5;
				data "Trucks in model" value: length(truck) color: rgb(141, 242, 215) marker_size:0 thickness:1.5;
				data "Cars entering by data" value: (WIM_2+DG_1516+DG_78+DG_26+from_termin) color: rgb(168, 50, 94) marker_size:0 thickness:0.75;
				data "Trucks entering by data" value:(WIM_2_lkw+DG_1516_lkw+DG_78_lkw+DG_26_lkw+from_termin_lkw) color: rgb(34, 117, 115) marker_size:0 thickness:0.75;	
			}
			chart "Counters DG22-23" type: series size:{0.5,0.2} position: {0,0.2} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Cars counted in model" value: (DG22+DG23) color: rgb(242, 141, 186) marker_size:0 thickness:1.5;
				data "Trucks counted in model" value: (DG22_lkw+DG23_lkw) color: rgb(141, 242, 215) marker_size:0 thickness:1.5;
				data "Cars passing by counters data" value: (DG_22+DG_23) color: rgb(168, 50, 94)  marker_size:0 thickness:1.5;	
				data "Trucks passing by counters data" value: (DG_22_lkw+DG_23_lkw) color: rgb(34, 117, 115) marker_size:0 thickness:1.5;
			}
			chart "Counters DG24-25" type: series size:{0.5,0.2} position: {0.5,0.2} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Cars counted in model" value: (DG24+DG25) color: rgb(242, 141, 186) marker_size:0 thickness:1.5;
				data "Trucks counted in model" value: (DG24_lkw+DG25_lkw) color: rgb(141, 242, 215) marker_size:0 thickness:1.5;
				data "Cars passing by counters data" value: (DG_24+DG_25) color: rgb(168, 50, 94)  marker_size:0 thickness:1.5;	
				data "Trucks passing by counters data" value: (DG_24_lkw+DG_25_lkw) color: rgb(34, 117, 115) marker_size:0 thickness:1.5;
			}
			chart "Time Delay" type: series size:{0.5,0.2} position: {0,0.4} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Time delay in s" value: road mean_of each.time_delay color: #gray marker_size:0 thickness:1.5;
			}
			chart "Traffic type" type: pie size:{0.5,0.2} position: {0.5,0.4} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Cars" value: length(car) color:rgb(168, 50, 94);
				data "Trucks" value:  length(truck) color: rgb(34, 117, 115);
			}
			chart "Speed index" type: series size:{0.5,0.2} position: {0,0.6} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Average Speed" value: car mean_of each.real_speed color: #white marker_size:0 thickness:1.5;
				data "Max Speed Now" value: car max_of each.real_speed color: rgb(242, 141, 186) marker_size:0 thickness:1.5;
			}
			chart "Speed Drop" type: series size:{0.5,0.2} position: {0,0.8} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Speed Drop in %" value: road mean_of each.speed_drop color: #gray marker_size:0 thickness:1.5;
			}
			chart "Flow" type: series size:{0.5,0.2} position: {0.5,0.6} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Current Flow in cars/h" value: road mean_of each.flow color: #gray marker_size:0 thickness:1.5;
			}
			chart "Density" type: series size:{0.5,0.2} position: {0.5,0.8} background: rgb(55,62,70) axes: #white color: #white legend_font:("Calibri") label_font:("Calibri") tick_font:("Calibri") title_font:("Calibri"){
				data "Current Density in cars/m" value: road max_of each.density color: #gray marker_size:0 thickness:1.5;
			}
			
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background:rgb(55,62,70) transparency:1.0{
				rgb text_color<-rgb(179,186,196);
				float y <-12#px;
				draw time_info at:{25#px,y+8#px} color:#white font:font("Calibri",12,#plain);
			}
		}
		display map type:java2D   background: rgb(30,40,49) camera_interaction:true draw_env:false { //use opengl-java2D to operate outside boundary areas
			image site_plan transparency:0.8 refresh:false;
			species road aspect:default;
			species car aspect:default;
			species truck aspect:default;
			species sand_truck aspect:default;
			species traffic_light aspect:default;
			species sand aspect:default;
			species landfill aspect:default;
			species sand_sources aspect:default;
			//species shoreline aspect:default;
			
			
			overlay position: { 5, 5 } size: { 240 #px, 680 #px } background:rgb(55,62,70) transparency:1.0{
				rgb text_color<-rgb(179,186,196);
				float y <-12#px;
				draw time_info at:{25#px,y+8#px} color:#white font:font("Calibri",12,#plain);
				y <-y+14#px;
                draw  "Scenario: "+string(scenario) at:{25#px,y+8#px} color:#white font:font("Calibri",12,#plain);
                y <-y+14#px;
                draw  "Amount of trucks needed: "+string(scenario) at:{25#px,y+8#px} color:#white font:font("Calibri",12,#plain);
               	y <-y+14#px;
                draw  "One truck every: "+string(inv_truck_frequency*length(sand_sources where each.active))+" minutes from each sand source" at:{25#px,y+8#px} color:#white font:font("Calibri",12,#plain);
                
			}
////////////////////User interaction starts here		
			event mouse_move action: move;
			event mouse_up action: click;
			event 'r' action: kill;
			event 'c' action: duplicate;
			graphics "Full target" {
				int size <- length(moved_agents);
				if (size > 0){
					rgb c1 <- rgb(62,120,119);
					rgb c2 <- rgb(62,120,119);
					draw zone at: target empty: false border: false color: (can_drop ? c1 : c2);
					draw string(size) at: target + { -15, -15 } font: font("Calibri", 8, #plain) color: rgb(179,186,196);
					draw "'r': remove" at: target + { -15, 0 } font: font("Calibri", 8, #plain) color: rgb(179,186,196);
					draw "'c': copy" at: target + { -15, 15 } font: font("Calibri", 8, #plain) color: rgb(179,186,196);
				}
			}
////////////////////User interaction ends here	
		}
	}
}
