variable "base_domain" {}

data "aws_route53_zone" "dns_zone" {
    name = "${var.base_domain}"
}

resource "aws_route53_record" "eu_cluster" {
  depends_on = [ "aws_instance.eu_cockroach" ]
  zone_id = "${data.aws_route53_zone.dns_zone.zone_id}"
  name    = "eu.cockroach"
  type    = "CNAME"
  ttl     = "300"
  records = [ "${aws_elb.eu_elb_cockroach.*.dns_name}" ]
}

output "europe_entrypoint" {
  value = "${aws_route53_record.eu_cluster.name}.${var.base_domain}"
}
