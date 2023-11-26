module Kuiq
  module View
    class RetriesTable
      include Glimmer::LibUI::CustomControl
    
      option :job_manager
    
      body {
        table {
          text_column('Next Retry')
          text_column('Retry Count')
          text_column('Queue')
          text_column('Job')
          text_column('Arguments')
          text_column('Error')
          
          cell_rows <= [job_manager, :retried_jobs]
        }
      }
    end
  end
end
