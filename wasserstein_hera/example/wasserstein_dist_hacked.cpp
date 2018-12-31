#include <iostream>
#include <locale>
#include <iomanip>
#include <vector>

#include "wasserstein.h"
#include <chrono>
using namespace std::chrono;



int main(int argc, char* argv[])
{
    using PairVector = std::vector<std::pair<double, double>>;
    std::vector< PairVector > diags;
    for ( int i = 1 ; i != argc ; ++i )
    {
		PairVector diagramA;
		hera::read_diagram_point_set<double, PairVector>(argv[i], diagramA);
		std::cout << "Reading file : " << argv[i] << std::endl;
		//hera::remove_duplicates<double>(diagramA);
		diags.push_back( diagramA );
	}


	//Hera parameters.
    hera::AuctionParams<double> params;
    params.wasserstein_power = 2.0; 
    params.delta = 0.01;    
    params.internal_p = hera::get_infinity<double>();
    params.initial_epsilon= 0.0 ;
    params.epsilon_common_ratio = 0.0 ;
    params.max_bids_per_round = std::numeric_limits<size_t>::max();
    params.gamma_threshold = 0.0;
    std::string log_filename_prefix = "";
    params.max_num_phases = 800;

	high_resolution_clock::time_point t1 = high_resolution_clock::now();
	std::vector< std::vector<double> > result( diags.size() , std::vector<double>(diags.size(),0) );
	
	double res;
	for ( size_t i = 0 ; i != diags.size() ; ++i )
	{
		for ( size_t j = i+1 ; j != diags.size() ; ++j )
		{
			res = hera::wasserstein_dist(diags[i], diags[j], params, log_filename_prefix);
			result[i][j] = result[j][i] = res;			
		}
    }
    high_resolution_clock::time_point t2 = high_resolution_clock::now();
    auto duration = duration_cast<seconds>( t2 - t1 ).count();

    std::cout << "duration : " <<  duration << std::endl;
    std::ofstream out;
    out.open("duration");
    out << duration;
    out.close();
    
    std::ofstream out1("result");
    for ( size_t i = 0 ; i != result.size() ; ++i )
    {
		for ( size_t j = 0  ; j != result.size() ; ++j )
		{
			out1 << std::setprecision(15) << result[i][j] << " ";
		}
		out1 << std::endl;
	}
	out1.close();
    

    return 0;

}
